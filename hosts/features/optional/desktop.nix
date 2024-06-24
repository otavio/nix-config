{
  hardware.graphics.enable = true;

  programs.adb.enable = true;
  programs.dconf.enable = true;
  users.users.otavio.extraGroups = [ "adbusers" ];

  services.gnome.gnome-keyring.enable = true;
}
