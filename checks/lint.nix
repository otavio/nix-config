{ pkgs, flake, ... }:
pkgs.runCommand "lint-code"
{
  nativeBuildInputs = with pkgs; [ nixpkgs-fmt deadnix statix ];
} ''
  deadnix --fail ${flake.outPath}
  nixpkgs-fmt --check ${flake.outPath}
  touch $out
''
