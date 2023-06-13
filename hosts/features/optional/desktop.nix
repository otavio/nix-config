_:

{
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  programs.adb.enable = true;
  programs.dconf.enable = true;
  users.users.otavio.extraGroups = [ "adbusers" ];

  services.gnome.gnome-keyring.enable = true;
}
