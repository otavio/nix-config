{ graphical, hostname, ... }:

{
  imports =
    [
      ./global
      ./features/emacs
      ./features/flameshot
      ./features/gpg
      ./features/ossystems-specific

      ./base.nix
      ./zsh.nix
    ] ++ (if graphical && hostname != "poirot" then [
      ./desktop.nix
      ./gtk.nix
      ./i3.nix
    ] else [ ]);
}
