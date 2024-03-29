{ pkgs, ... }:

{
  imports = [
    ./features/global
    ./features/alacritty
    ./features/brave
    ./features/dunst
    ./features/flameshot
    ./features/emacs
    ./features/gtk
    ./features/i3wm
    ./features/unclutter
    ./features/parcellite
    ./features/xdg
    ./features/zathura
    ./features/zsh
  ];

  home.packages = with pkgs; [
    anydesk
  ];
}
