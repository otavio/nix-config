{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    anydesk
    gthumb
    nixpkgs-fmt
    nixpkgs-review
    scrcpy
  ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source =
    ./parcellite/parcelliterc;

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ./dunst/skype;

  programs.brave.enable = true;
}
