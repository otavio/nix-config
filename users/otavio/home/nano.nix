_:

{
  imports = [
    ./global
    ./features/alacritty
    ./features/flameshot
    ./features/emacs
    ./features/unclutter
    ./features/xdg
    ./features/zathura

    ./base.nix
    ./zsh.nix
    ./desktop.nix
    ./gtk.nix
    ./i3.nix
  ];
}
