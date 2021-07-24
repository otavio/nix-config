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

  programs.urxvt.enable = true;
  xresources.extraConfig = ''
    !! Colors, stolen from http://xcolors.net/dl/derp
    *color0:   #111111
    *color8:   #666666
    *color1:   #d36265
    *color9:   #ef8171
    *color2:   #aece91
    *color10:  #cfefb3
    *color3:   #e7e18c
    *color11:  #fff796
    *color4:   #5297cf
    *color12:  #74b8ef
    *color5:   #963c59
    *color13:  #b85e7b
    *color6:   #5E7175
    *color14:  #A3BABF
    *color7:   #bebebe
    *color15:  #ffffff

    !! rxvt configuration
    URxvt.termName: rxvt-unicode-256color
    URxvt.foreground: white
    URxvt.background: rgba:0000/0000/0000/dddd
    URxvt.cursorColor: green
    URxvt.depth: 32
    URxvt.cursorBlink: False
    URxvt*colorIT: #ff7f00
    URxvt.scrollBar: False
    URxvt.scrollTtyOutput: False
    URxvt.scrollTtyKeypress: True
    URxvt.scrollWithBuffer: True
    URxvt.jumpScroll: True
    URxvt.skipScroll: True
    URxvt.saveLines: 5000
    URxvt.urgentOnBell:  true
    URxvt.font: xft:DejaVu Sans Mono-12,xft:DejaVu Sans Mono for Powerline-12
    URxvt.letterSpace: -1
    URxvt.iso14755: False
    URxvt.perl-ext-common: default,-option-popup,-selection-popup,font-size,selection-to-clipboard,readline,url-select
    URxvt.keysym.C-equal: perl:font-size:increase
    URxvt.keysym.C-minus: perl:font-size:decrease
    URxvt.keysym.C-i: perl:url-select:select_next
    URxvt.url-select.launcher: firefox
    URxvt.url-select.underline: true
  '';

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
