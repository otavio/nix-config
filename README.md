Configuration repository
=

Installation inside an existing Linux system
===

For Debian-based systems we need to have `curl`, `rsync` and `zsh` before proceeding. Use:
```sh
sudo apt install -y curl rsync zsh
```

The user must use `zsh` as shell so do it using:
```sh
sudo usermod -s /bin/zsh otavio
```

Install the daemon inside the existing operating system with:
```sh
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

Finally, clone this repository as:
```sh
mkdir -p ~/src
git clone git@github.com:otavio/nix-config.git src/nix-config
```

Add the required channels to the environment, using:
```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --add https://channels.nixos.org/nixpkgs-unstable nixpkgs
nix-channel --update
```

Then install the `home-manager` to allow it to switch to the environment, using:
```sh
# On non-NixOS systems, we need to export NIX_PATH manually,
# see: https://github.com/NixOS/nix/issues/2033
export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

# Install home-manager in the profile
nix-env '<home-manager>' -iA home-manager

# Do the actual switch
home-manager switch
```
