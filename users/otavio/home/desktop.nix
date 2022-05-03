{ config, pkgs, ... }:
let
  irssiWrapper = pkgs.writeScriptBin "irssi" ''
    export LIBERACHAT_PASSWORD=$(sops --decrypt --extract '["irssi-nickserv"]' $HOME/nix-config/secrets/secrets.yaml)
    ${pkgs.irssi}/bin/irssi
  '';
in
{
  xdg.enable = true;

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
    irssiWrapper
    tdesktop
    libreoffice
    nixpkgs-fmt
    nixpkgs-review
    pavucontrol
    scrcpy
    skypeforlinux
    slack
    vlc
    zoom-us
    zulip
  ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source =
    ./parcellite/parcelliterc;

  programs.alacritty.enable = true;

  programs.zathura.enable = true;

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ./dunst/skype;

  services.flameshot.enable = true;

  home.file.".irssi" = {
    source = ./irssi;
    recursive = true;
  };

  programs.brave.enable = true;
}
