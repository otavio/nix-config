{ pkgs }:

let
  luks = "/dev/disk/by-uuid/faae5ddb-df82-4a23-8a24-eedd6356ccff";
  mnt = "/tmp/otavio/keys";
  sudo = "/run/wrappers/bin/sudo";
in
pkgs.writeShellApplication {
  name = "keys-load";
  runtimeInputs = with pkgs; [
    coreutils
    cryptsetup
    gawk
    gnused
    gnupg
    openssh
    pinentry-qt
    util-linux
    yad
  ];
  text = ''
    # One passphrase opens the keys partition and is preset for every SSH key;
    # GPG keys still prompt through pinentry when used. --gui asks through
    # pinentry-qt instead of the terminal.
    gui=false
    [ "''${1:-}" = --gui ] && gui=true

    case "''${PINENTRY_USER_DATA:-}" in
      agent:*)
        echo "keys-load must be run by the user, not by an AI agent." >&2
        exit 1 ;;
    esac

    export SSH_AUTH_SOCK
    SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

    fail() {
      if $gui; then
        yad --title "Unlock credentials" --image=dialog-error --text="$1" --button=OK:0 || true
      else
        echo "ERROR: $1" >&2
      fi
      exit 1
    }

    # Assuan percent-escapes %, CR and LF in the returned passphrase.
    unescape() {
      local s=$1 out="" c
      while [[ $s =~ ^([^%]*)%([0-9A-Fa-f]{2})(.*)$ ]]; do
        printf -v c '%b' "\\x''${BASH_REMATCH[2]}"
        out+=''${BASH_REMATCH[1]}$c
        s=''${BASH_REMATCH[3]}
      done
      printf '%s' "$out$s"
    }

    ask() {
      local error=$1 reply
      if $gui; then
        reply=$(printf '%s\n' \
          "SETTITLE Unlock credentials" \
          "SETDESC Passphrase for the keys partition and SSH keys." \
          "SETPROMPT Passphrase:" \
          ''${error:+"SETERROR $error"} \
          GETPIN BYE | pinentry-qt) || true
        reply=$(printf '%s\n' "$reply" | sed -n 's/^D //p')
        [ -n "$reply" ] || exit 1
        unescape "$reply"
      else
        [ -z "$error" ] || echo "$error" >&2
        read -rsp "Passphrase (partition + SSH keys): " reply
        echo >&2
        printf '%s' "$reply"
      fi
    }

    # The LUKS keyslot shares the passphrase, so it validates it even when the
    # partition is already open.
    error=
    for _ in 1 2 3; do
      pass=$(ask "$error")
      printf '%s' "$pass" | ${sudo} cryptsetup open --test-passphrase --key-file=- ${luks} && break
      error="Wrong passphrase, try again."
      pass=
    done
    [ -n "$pass" ] || fail "Wrong passphrase."

    mkdir -p ${mnt}
    if ! mountpoint -q ${mnt}; then
      if [ ! -e /dev/mapper/keys ]; then
        printf '%s' "$pass" | ${sudo} cryptsetup open --key-file=- ${luks} keys || fail "Could not open the keys partition."
      fi
      ${sudo} mount /dev/mapper/keys ${mnt} || fail "Could not mount the keys partition."
    fi

    $gui || gpg-connect-agent --quiet updatestartuptty /bye > /dev/null

    awk '!/^#/ && NF { print $1 }' ~/.gnupg/sshcontrol | while read -r grip; do
      printf '%s' "$pass" | ${pkgs.gnupg}/libexec/gpg-preset-passphrase --preset "$grip"
    done
    unset pass

    # TODO: drop id_rsa once nothing depends on it anymore.
    errors=
    for key in id_ed25519 id_rsa; do
      ssh-add -T "$HOME/.ssh/$key.pub" 2>/dev/null || errors+="$key does not sign; import it with: ssh-add ~/.ssh/$key"$'\n'
    done

    [ -z "$errors" ] || fail "''${errors%$'\n'}"
    $gui || echo "Keys loaded."
  '';
}
