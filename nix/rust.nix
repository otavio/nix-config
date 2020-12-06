{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    binutils

    cargo-audit
    cargo-bloat
    cargo-cache
    cargo-edit
    cargo-outdated
    cargo-release
    cargo-udeps
    cargo-watch
    cargo-update
    rustup
  ];
}
