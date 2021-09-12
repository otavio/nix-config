{ config, pkgs, ... }:

{
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  programs.adb.enable = true;
  users.users.otavio.extraGroups = ["adbusers"];
  programs.dconf.enable = true;

  services.gnome.gnome-keyring.enable = true;
}
