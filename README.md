Configuration repository
=

Installation inside an existing Linux system
===

For Debian-based systems we need to have `rsync` and `zsh` before proceeding. Use:
```sh
sudo apt install -y rsync zsh
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
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update
```

Then install the `home-manager` to allow it to switch to the environment, using:
```sh
nix-shell '<home-manager>' -A install
home-manager switch
```
