# Refuse interactive passphrase/credential prompts when a command runs inside an
# AI coding agent (Claude Code, Codex). Instead of blocking on a hidden prompt,
# the command fails fast with a notice telling the agent to ask the user to
# perform the action (or unlock the key) themselves.
#
# Two channels, because the credential paths differ:
#
#   * GPG goes through the long-lived gpg-agent daemon, so per-command env is not
#     visible to its pinentry. The only lever is PINENTRY_USER_DATA, which gpg
#     forwards to pinentry. SSH signing requests carry no environment at all,
#     so ssh registers the agent's connection beforehand (see sshStartupEnv).
#
#   * SSH/git invoke their askpass helper directly, so a plain env var is enough.
#     SSH_ASKPASS_REQUIRE=force makes ssh use it even when a tty is present.
{ pkgs }:

let
  # Qt dialog on X; falls back to curses when there is no display.
  realPinentry = pkgs.lib.getExe' pkgs.pinentry-qt "pinentry-qt";

  # Refuses with GPG_ERR_CANCELED, which stops gpg retrying. It never writes to
  # the caller's tty: pinentry is spawned by the detached gpg-agent, so that tty
  # is the agent's own terminal and a raw write corrupts a full-screen TUI; gpg
  # surfaces the refusal on the failing command's stderr instead. It exits right
  # after refusing because gpg-agent may never send BYE.
  pinentry = pkgs.writeShellApplication {
    name = "pinentry";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      # A prompt cannot be tied to the ssh that caused it, so any live or recent
      # registration refuses all prompts; one that belongs to the user can be
      # retried.
      # Background fetches repeat every few minutes, so only agents notify.
      refuse=false
      notify=false
      for f in "${agentSshDir}"/*; do
        [ -e "$f" ] || continue
        pid="''${f##*/}"
        if [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = ssh ] || [ -n "$(find "$f" -newermt '15 seconds ago')" ]; then
          refuse=true
          [ "$(cat "$f" 2>/dev/null)" = background ] || notify=true
        else
          rm -f "$f"
        fi
      done

      case "''${PINENTRY_USER_DATA:-}" in
        agent:*) refuse=true; notify=true ;;
      esac
      $refuse || exec ${realPinentry} "$@"

      if $notify; then
        ${pkgs.libnotify}/bin/notify-send -u critical "Passphrase refused" \
          "An AI agent needed a GPG/SSH key unlocked. Run keys-load or the command yourself." > /dev/null 2>&1 || true
      fi

      notice="Passphrase entry is refused for AI agents and background processes. Ask the user to unlock the key (keys-load) or run this command themselves; do not retry."

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

  # Being invoked at all means an interactive prompt was about to appear.
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

  agentSshDir = "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agent-ssh";

  # Run from ssh's Match exec, whose parent is ssh itself. A user's ssh hands
  # gpg-agent its tty and display so pinentry shows up where they are. Nobody
  # is watching an AI agent's ssh or one without a controlling terminal
  # (periodic git fetches from T3 or Obsidian), so those register instead.
  sshStartupEnv = pkgs.writeShellApplication {
    name = "gpg-agent-ssh-startup-env";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      kind=
      case "''${PINENTRY_USER_DATA:-}" in
        agent:*) kind=agent ;;
        *)
          stat=$(cat "/proc/$PPID/stat")
          read -r _ _ _ _ tty _ <<< "''${stat##*) }"
          [ "$tty" = 0 ] && kind=background
          ;;
      esac

      if [ -n "$kind" ]; then
        mkdir -p "${agentSshDir}"
        echo "$kind" > "${agentSshDir}/$PPID"
      else
        ${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
      fi
    '';
  };
in
{
  inherit askpass pinentry sshStartupEnv;

  mkAgentEnv = marker: {
    PINENTRY_USER_DATA = "agent:${marker}";
    SSH_ASKPASS = pkgs.lib.getExe askpass;
    SSH_ASKPASS_REQUIRE = "force";
    GIT_ASKPASS = pkgs.lib.getExe askpass;
  };
}
