{ config
, graphical
, ...
}:

{
  imports =
    [
      ./base.nix
      ./git.nix
      ./emacs.nix
      ./zsh.nix
    ] ++ (if graphical then [
      ./desktop.nix
      ./go.nix
      ./gtk.nix
      ./i3.nix
      ./nix.nix
      ./rust.nix
    ] else [ ]);

  # Symlink nix-config to .config/nixpkgs, so i can use `home-manager switch`
  home.file."home-config" = {
    target = ".config/nixpkgs";
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/nix-config";
  };
}