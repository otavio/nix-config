{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    anydesk
    discord
    gthumb
    nixpkgs-fmt
    nixpkgs-review
    scrcpy
    skypeforlinux
    slack
    tdesktop
  ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source =
    ./parcellite/parcelliterc;

  programs.alacritty = {
    enable = true;
    settings = {
      env.term = "alacritty";
    };
  };

  home.sessionVariables = {
    TERMINAL = "alacritty";
    TERM = "xterm-256color";
  };

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ./dunst/skype;

  programs.brave.enable = true;
}
