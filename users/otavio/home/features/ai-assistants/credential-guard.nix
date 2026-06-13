# Refuse interactive passphrase/credential prompts when a command runs inside an
# AI coding agent (Claude Code, Codex). Instead of blocking on a hidden prompt,
# the command fails fast with a notice telling the agent to ask the user to
# perform the action (or unlock the key) themselves.
#
# Two channels, because the credential paths differ:
#
#   * GPG goes through the long-lived gpg-agent daemon, so per-command env is not
#     visible to its pinentry. The only lever is PINENTRY_USER_DATA, which gpg
#     forwards to pinentry. The wrapper refuses when it sees an `agent:*` marker
#     and otherwise execs the real curses pinentry.
#
#   * SSH/git invoke their askpass helper directly, so a plain env var is enough.
#     SSH_ASKPASS_REQUIRE=force makes ssh use it even when a tty is present.
{ pkgs }:

let
  realPinentry = pkgs.lib.getExe' pkgs.pinentry-curses "pinentry-curses";

  # Minimal Assuan pinentry: acknowledge the handshake/options, then refuse the
  # first passphrase or confirmation with a canceled error (GPG_ERR_CANCELED,
  # which stops gpg retrying). It deliberately does not write to the caller's
  # tty — pinentry is spawned by the detached gpg-agent, so that tty is the
  # agent's own terminal and a raw write corrupts a full-screen TUI; gpg
  # surfaces the refusal on the failing command's stderr instead. It exits
  # immediately rather than looping for a BYE that gpg-agent may never send.
  pinentry = pkgs.writeShellApplication {
    name = "pinentry";
    text = ''
      case "''${PINENTRY_USER_DATA:-}" in
        agent:*) ;;
        *) exec ${realPinentry} "$@" ;;
      esac

      notice="GPG passphrase entry is disabled inside AI agents. Ask the user to run this command or unlock the key (gpg/gpg-agent) themselves; do not retry."

      printf 'OK Pleased to meet you\n'
      while IFS= read -r line; do
        case "$line" in
          GETPIN* | CONFIRM*)
            printf 'ERR 83886179 Operation cancelled - %s\n' "$notice"
            exit 0 ;;
          BYE*) printf 'OK closing connection\n'; exit 0 ;;
          *) printf 'OK\n' ;;
        esac
      done
    '';
  };

  # SSH / git askpass. Its mere invocation means an interactive prompt was about
  # to appear, so it always refuses. The prompt text arrives as $1; SSH_ASKPASS
  # also routes host-key confirmations here, so tailor the guidance to each.
  askpass = pkgs.writeShellApplication {
    name = "agent-askpass-guard";
    text = ''
      prompt="''${1:-<none>}"
      case "$prompt" in
        *"(yes/no"* | *fingerprint*)
          {
            echo "=============================================================="
            echo "AGENT NOTICE: confirming an unknown SSH host key is blocked"
            echo "inside AI coding agents. Do NOT retry this command."
            echo "Prompt was: $prompt"
            echo "Ask the user to verify and accept the host key themselves"
            echo "(or to run this command), then continue."
            echo "=============================================================="
          } >&2
          ;;
        *)
          {
            echo "=============================================================="
            echo "AGENT NOTICE: interactive passphrase/credential entry is blocked"
            echo "inside AI coding agents. Do NOT retry this command."
            echo "Prompt was: $prompt"
            echo "Ask the user to run this command, or to unlock the credential"
            echo "(e.g. 'ssh-add', or a manual push/sign), themselves."
            echo "=============================================================="
          } >&2
          ;;
      esac
      exit 1
    '';
  };
in
{
  inherit pinentry askpass;

  mkAgentEnv = marker: {
    PINENTRY_USER_DATA = "agent:${marker}";
    SSH_ASKPASS = pkgs.lib.getExe askpass;
    SSH_ASKPASS_REQUIRE = "force";
    GIT_ASKPASS = pkgs.lib.getExe askpass;
  };
}
