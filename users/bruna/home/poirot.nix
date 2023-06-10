{ pkgs, ... }:
{
  services.flameshot.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home.packages = with pkgs; [
    chromium
    libreoffice
    system-config-printer
    simple-scan
  ];

  home.stateVersion = "22.11";
}
