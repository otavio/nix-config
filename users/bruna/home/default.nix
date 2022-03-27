{ config, pkgs, ... }:
{
  services.flameshot.enable = true;

  home.packages = with pkgs; [
    anydesk
    chromium
    libreoffice
    system-config-printer
    simple-scan
  ];

  home.stateVersion = "22.11";
}
