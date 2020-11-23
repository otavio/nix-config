{ config, pkgs, ... }:
let
  # https://docs.microsoft.com/en-us/answers/questions/42095/sharing-screen-not-working-anymore-bug.html
  teams = pkgs.teams.overrideAttrs (oldAttrs: rec{
    postFixup = oldAttrs.postFixup + ''
      rm $out/opt/teams/resources/app.asar.unpacked/node_modules/slimcore/bin/rect-overlay
    '';
  });
in
{
  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  home.packages = with pkgs; [
    anydesk
    discord
    firefox
    gthumb
    libreoffice
    nixpkgs-fmt
    pavucontrol
    scrcpy
    skypeforlinux
    slack
    teams
    topgrade
    vlc

    gnome3.gnome-keyring
  ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source = ../nix/parcellite/parcelliterc;

  programs.urxvt.enable = true;
  home.file.".Xresources".source = ../nix/urxvt/Xresources;

  programs.zathura.enable = true;

  xdg.configFile."topgrade.toml".source = ../nix/topgrade/topgrade.toml;

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ../nix/dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ../nix/dunst/skype;

  services.flameshot.enable = true;
}
