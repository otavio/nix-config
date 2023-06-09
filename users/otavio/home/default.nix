{ graphical, hostname, ... }:

{
  imports =
    [
      ./global

      ./base.nix
      ./emacs.nix
      ./tmux.nix
      ./zsh.nix
    ] ++ (if graphical && hostname != "poirot" then [
      ./desktop.nix
      ./go.nix
      ./gtk.nix
      ./i3.nix
      ./nix.nix
    ] else [ ]);
}
