{ pkgs, ... }:
{
  imports = [ ./default.nix ];

  services.flameshot.enable = true;

  home.packages = with pkgs; [
    chromium
    libreoffice
    system-config-printer
    simple-scan
  ];
}
