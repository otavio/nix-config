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
    cargo-insta
    cargo-limit
    cargo-msrv
    cargo-outdated
    cargo-readme
    cargo-release
    cargo-rr
    cargo-udeps
    cargo-update
    cargo-valgrind
    cargo-watch
    cargo-wipe
    rustup

    rust-analyzer
  ];
}
