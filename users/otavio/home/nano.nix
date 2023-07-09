_:

{
  imports = [
    ./global
    ./features/alacritty
    ./features/dunst
    ./features/flameshot
    ./features/emacs
    ./features/unclutter
    ./features/parcellite
    ./features/xdg
    ./features/zathura

    ./base.nix
    ./zsh.nix
    ./desktop.nix
    ./gtk.nix
    ./i3.nix
  ];
}
