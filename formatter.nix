{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "normalise_nix";
  runtimeInputs = with pkgs; [ nixpkgs-fmt statix ];
  text = ''
    set -o xtrace
    nixpkgs-fmt "''${@:-.}"
    statix fix "''${@:-.}"
  '';
}
