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
    gnupg
    openssh
    util-linux
  ];
  text = ''
    # One passphrase opens the keys partition and is preset for every SSH key;
    # GPG keys still prompt through pinentry when used.
    read -rsp "Passphrase (partition + SSH keys): " pass
    echo

    mkdir -p ${mnt}
    if ! mountpoint -q ${mnt}; then
      if [ ! -e /dev/mapper/keys ]; then
        echo Decrypting partition...
        printf '%s' "$pass" | ${sudo} cryptsetup open --key-file=- ${luks} keys 2> /dev/null ||
          ${sudo} cryptsetup -v open ${luks} keys || { echo ERROR; exit 1; }
      fi
      ${sudo} mount /dev/mapper/keys ${mnt} || { echo ERROR; exit 1; }
      echo "done"
    fi

    gpg-connect-agent --quiet updatestartuptty /bye > /dev/null

    awk '!/^#/ && NF { print $1 }' ~/.gnupg/sshcontrol | while read -r grip; do
      printf '%s' "$pass" | ${pkgs.gnupg}/libexec/gpg-preset-passphrase --preset "$grip"
    done
    unset pass

    # TODO: drop id_rsa once nothing depends on it anymore.
    echo Loading SSH keys...
    for key in id_ed25519 id_rsa; do
      ssh-add -T "$HOME/.ssh/$key.pub" || echo "ERROR: $key (import with: ssh-add ~/.ssh/$key)"
    done
  '';
}
