{ lib, config, pkgs, ... }:

{
  home = {
    username = lib.mkDefault "kadu";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.11";
  };

  home.packages = with pkgs; [
    gcompris
    tuxpaint
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-size = 32;
      text-scaling-factor = 1.25;
      clock-show-weekday = true;
    };

    "org/gnome/desktop/lockdown" = {
      disable-command-line = true;
      disable-lock-screen = true;
      disable-user-switching = true;
      user-administration-disabled = true;
    };

    "org/gnome/desktop/screensaver".lock-enabled = false;

    "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 900;

    "org/gnome/shell" = {
      disable-user-extensions = true;

      favorite-apps = [
        "org.kde.gcompris.desktop"
        "tuxpaint.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };
}
