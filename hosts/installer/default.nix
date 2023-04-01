{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-latin1-us";
  };

  nix = {
    settings = {
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };

    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      warn-dirty = false
    '';
  };

  services = {
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  environment.systemPackages = with pkgs; [ zile ];
}
