{ pkgs, flake, ... }:
pkgs.runCommand "lint-code"
  {
    nativeBuildInputs = with pkgs; [ deadnix ];
  }
  ''
    deadnix --fail ${flake.outPath}
    touch $out
  ''
