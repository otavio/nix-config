{ lib, ... }:

{
  # Workaround: Home Manager creates ~/.ssh/config as a symlink to the Nix
  # store, but SSH rejects symlinks with world-readable permissions. We use an
  # activation script to copy it with proper permissions instead.
  home.activation.fixSshConfigPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.ssh/config" ]; then
      target=$(readlink -f "$HOME/.ssh/config")
      rm "$HOME/.ssh/config"
      install -m 600 "$target" "$HOME/.ssh/config"
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ControlMaster = "auto";
        HashKnownHosts = false;
      };

      "code.ossystems.com.br" = {
        HostName = "code.ossystems.io";
      };

      "*.lab.ossystems" = {
        ForwardAgent = true;
        ForwardX11 = true;
        ForwardX11Trusted = true;
      };

      "gitlab.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
