{ pkgs, ... }:

{
  hardware.graphics.enable = true;

  programs.dconf.enable = true;

  services.gnome.gnome-keyring.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
}
