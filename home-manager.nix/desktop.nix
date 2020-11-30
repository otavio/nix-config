{ config, pkgs, ... }:

{
  imports =
    [
      ../nix/base.nix
      ../nix/desktop.nix
      ../nix/gtk.nix
      ../nix/i3.nix
      ../nix/rust.nix
      ../nix/zsh.nix
    ];

  nixpkgs.config.allowUnfree = true;
}
