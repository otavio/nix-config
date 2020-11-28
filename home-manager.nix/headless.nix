{ config, pkgs, ... }:

{
  imports =
    [
      ../nix/base.nix
      ../nix/zsh.nix
    ];
}
