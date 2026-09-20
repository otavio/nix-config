{ lib, ... }:

{
  # Home Manager creates ~/.ssh/config as a symlink to the Nix store, but SSH
  # rejects symlinks with world-readable permissions, so activation swaps it for
  # a 0600 copy -- which the next generation's checkLinkTargets then refuses to
  # overwrite unless it is cleared first.
  home.activation = {
    dropSshConfigCopy = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      run rm -f "$HOME/.ssh/config"
    '';

    fixSshConfigPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -L "$HOME/.ssh/config" ]; then
        target=$(readlink -f "$HOME/.ssh/config")
        run rm "$HOME/.ssh/config"
        run install -m 600 "$target" "$HOME/.ssh/config"
      fi
    '';
  };

  services.ssh-agent.enable = true;

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

      # Lab DHCP range: addresses rotate between hosts, so keys must not stick.
      "10.5.4.*" = {
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = "no";
      };

      "gitlab.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
