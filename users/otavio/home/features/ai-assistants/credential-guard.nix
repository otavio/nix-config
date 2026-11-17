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

  keysLoad = import ../gpg/keys-load.nix { inherit pkgs; };
  lockedIcon = pkgs.writeText "keys-locked.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="31" fill="#e01b24"/>
      <path d="M22 29v-6a10 10 0 0 1 20 0v6" fill="none" stroke="#fff" stroke-width="5"/>
      <rect x="16" y="29" width="32" height="22" rx="3" fill="#fff"/>
      <circle cx="32" cy="38" r="3.5" fill="#e01b24"/>
      <rect x="30.5" y="38" width="3" height="8" fill="#e01b24"/>
    </svg>
  '';

  # Stays until keys-load stops it, so a refusal waits for the user instead of
  # interrupting them. The tooltip follows the callers file, so requests
  # refused after the icon appeared are listed too.
  unlockTray = pkgs.writeShellApplication {
    name = "keys-unlock-tray";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.yad
    ];
    text = ''
      title="Credentials locked: click to unlock"
      seen=
      tail -n +1 -F "$1" 2> /dev/null | while IFS= read -r line; do
        # yad unescapes tooltip text, so literal backslashes are doubled.
        line=''${line//\\/\\\\}
        case "$seen" in *"• $line"*) continue ;; esac
        seen+="\\n• $line"
        printf 'tooltip:%s\\n\\nRequested by:%s\n' "$title" "$seen"
      done | yad --notification --listen --no-markup --image=${lockedIcon} \
        --text="$title" --command="${pkgs.lib.getExe keysLoad} --gui"
    '';
  };

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
      pkgs.gnused
    ];
    text = ''
      # A prompt cannot be tied to the ssh that caused it, so any live or recent
      # registration refuses all prompts; one that belongs to the user can be
      # retried.
      refuse=false
      callers=
      for f in "${agentSshDir}"/*; do
        [ -e "$f" ] || continue
        pid="''${f##*/}"
        if [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = ssh ] || [ -n "$(find "$f" -newermt '15 seconds ago')" ]; then
          refuse=true
          callers+="$(cat "$f" 2>/dev/null || true)"$'\n'
        else
          rm -f "$f"
        fi
      done

      case "''${PINENTRY_USER_DATA:-}" in
        agent:*) refuse=true; callers+="''${PINENTRY_USER_DATA#agent:}: gpg"$'\n' ;;
      esac
      $refuse || exec ${realPinentry} "$@"

      list="${agentSshDir}/.callers"
      printf '%s' "$callers" | sed '/^$/d' >> "$list"
      ${pkgs.systemd}/bin/systemd-run --user --quiet --collect --unit=keys-unlock-tray \
        -E DISPLAY="''${DISPLAY:-:0}" ''${XAUTHORITY:+-E XAUTHORITY="$XAUTHORITY"} \
        -p ExecStopPost="${pkgs.coreutils}/bin/rm -f $list" \
        ${pkgs.lib.getExe unlockTray} "$list" > /dev/null 2>&1 || true

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
      describe() {
        local args remote what dir
        mapfile -d "" -t args < "/proc/$PPID/cmdline"
        remote=''${args[-1]//\'/}
        case "$remote" in
          git-upload-pack\ *) what="fetch ''${remote#* }" ;;
          git-receive-pack\ *) what="push ''${remote#* }" ;;
          *) what="ssh ''${args[*]:1}" ;;
        esac
        dir=$(readlink "/proc/$PPID/cwd")
        echo "$kind: $what in ''${dir/#$HOME/\~}"
      }

      if [ -n "$kind" ]; then
        mkdir -p "${agentSshDir}"
        # The redirection registers the pid even if describing it fails.
        describe > "${agentSshDir}/$PPID" 2> /dev/null || true
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
