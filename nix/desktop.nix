{ config, pkgs, ... }:
{
  xdg.enable = true;

  # We force the override so we workaround the error below:
  #   Existing file '/.../.config/mimeapps.list' is in the way of
  #   '/nix/store/...-home-manager-files/.config/mimeapps.list'
  # Issue: https://github.com/nix-community/home-manager/issues/1213
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    anydesk
    discord
    gthumb
    irssi
    libreoffice
    nixpkgs-fmt
    nixpkgs-review
    pavucontrol
    scrcpy
    skypeforlinux
    slack
    teams
    topgrade
    vlc
    zoom-us
    zulip

    gnome3.gnome-keyring
  ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source = ../nix/parcellite/parcelliterc;

  programs.alacritty.enable = true;

  programs.zathura.enable = true;

  xdg.configFile."topgrade.toml".source = ../nix/topgrade/topgrade.toml;

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ../nix/dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ../nix/dunst/skype;

  services.flameshot.enable = true;

  home.file.".irssi" = {
    source = ../nix/irssi;
    recursive = true;
  };
}
