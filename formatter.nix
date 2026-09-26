{ inputs, pkgs, ... }:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  imports = [
    inputs.pedantix.treefmtModules.default
    ./treefmt.nix
  ];
}
