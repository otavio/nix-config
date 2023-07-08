_:

{
  imports = [
    ./global
    ./features/emacs
    ./features/flameshot
    ./features/gpg
    ./features/ossystems-specific

    ./base.nix
    ./zsh.nix
    ./desktop.nix
    ./gtk.nix
    ./i3.nix
  ];
}
