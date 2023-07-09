{
  services.dunst.enable = true;
  xdg.configFile = {
    "dunst/dunstrc".source = ./dunstrc;
    "dunst/skype".source = ./skype;
  };
}
