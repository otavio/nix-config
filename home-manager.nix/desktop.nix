{ config, pkgs, ... }:

{
  imports =
    [
      ../nix/base.nix
      ../nix/zsh.nix
      ../nix/desktop.nix
      ../nix/gtk.nix
      ../nix/i3.nix
    ];

  nixpkgs.config.allowUnfree = true;
}
