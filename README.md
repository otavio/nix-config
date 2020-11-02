Configuration repository
=

Channels

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/release-20.09.tar.gz home-manager
nix-channel --add https://nixos.org/channels/nixos-20.09 nixos
nix-channel --update
```

To install the Rust toolchain and configure it for my use, I use:

```sh
rustup toolchain install nightly --profile=minimal --component rustfmt clippy
```

