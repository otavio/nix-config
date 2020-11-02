{ config, pkgs, ... }:

{
  imports =
    [
      ../nix/base.nix
      ../nix/desktop.nix
      ../nix/i3.nix
    ];

  nixpkgs.config.allowUnfree = true;
}
