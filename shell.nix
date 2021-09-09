{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "nix-config";
  buildInputs = [
    gnupg
    git-secret
  ];
}
