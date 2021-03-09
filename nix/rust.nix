{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    binutils

    cargo-audit
    cargo-bloat
    cargo-cache
    cargo-cross
    cargo-edit
    cargo-limit
    cargo-outdated
    cargo-readme
    cargo-release
    cargo-udeps
    cargo-update
    cargo-valgrind
    cargo-watch
    cargo-wipe
    rustup

    rust-analyzer
  ];
}
