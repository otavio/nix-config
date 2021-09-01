{ config, pkgs, ... }:

{
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  programs.adb.enable = true;
  users.users.otavio.extraGroups = ["adbusers"];

  services.dbus.packages = with pkgs; [ gnome3.dconf ];
}
