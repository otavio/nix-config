{ graphical, hostname, ... }:

{
  imports =
    [
      ./global
      ./features/flameshot
      ./features/gpg

      ./base.nix
      ./emacs.nix
      ./tmux.nix
      ./zsh.nix
    ] ++ (if graphical && hostname != "poirot" then [
      ./desktop.nix
      ./gtk.nix
      ./i3.nix
    ] else [ ]);
}
