{ pkgs, ... }:

{
  imports = [
    ./features/global
    ./features/alacritty
    ./features/android
    ./features/brave
    ./features/dunst
    ./features/flameshot
    ./features/emacs
    ./features/gtk
    ./features/i3wm
    ./features/unclutter
    ./features/xdg
    ./features/zathura
    ./features/zsh
  ];

  home.packages = with pkgs; [
    anydesk
  ];
}
