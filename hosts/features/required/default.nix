# This file holds config that i use on all hosts
{ pkgs, ... }:
{
  imports = [
    ./console.nix
    ./locale.nix
    ./home-manager.nix
    ./nix.nix
    ./nixpkgs.nix
    ./openssh.nix
    ./sops.nix
    ./upgrade-diff.nix
  ];

  system.stateVersion = "22.05";
}
