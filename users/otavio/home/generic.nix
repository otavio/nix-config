{
  imports = [
    ./features/global

    # Nix 1.19.2 fails to build a derivation containing a symlink to store path.
    #
    # Refs:
    # - https://github.com/nix-community/home-manager/issues/4692
    # - https://github.com/NixOS/nix/issues/9579
    #./features/home-manager-switch

    ./features/emacs
  ];
}
