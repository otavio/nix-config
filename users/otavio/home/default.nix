{ config, outputs, graphical, hostname, ... }:

{
  imports =
    [
      ./base.nix
      ./git.nix
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

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  # Symlink nix-config to .config/home-manager, so i can use `home-manager switch`
  home.file."home-config" = {
    target = ".config/home-manager";
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/nix-config";
  };
}
