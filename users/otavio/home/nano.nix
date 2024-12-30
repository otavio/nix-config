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
    ./features/swaywm
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
