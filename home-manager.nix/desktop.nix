{ config, pkgs, ... }:

{
  imports = [
    ../nix/base.nix
    ../nix/desktop.nix
    ../nix/go.nix
    ../nix/gtk.nix
    ../nix/i3.nix
    ../nix/nix.nix
    ../nix/rust.nix
    ../nix/zsh.nix
  ];
}
