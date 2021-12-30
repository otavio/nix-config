{ config, pkgs, ... }:

{
  imports = [
    ../nix/base.nix
    ../nix/emacs.nix
    ../nix/zsh.nix
  ];
}
