{ lib, config, pkgs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = lib.mkDefault "bruna";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
  };

  services.flameshot.enable = true;

  home.packages = with pkgs; [
    chromium
    libreoffice
    system-config-printer
    simple-scan
  ];
}
