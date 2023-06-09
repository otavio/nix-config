{ config, ... }:

{
  # Symlink nix-config to .config/home-manager, so i can use `home-manager switch`
  home.file."home-config" = {
    target = ".config/home-manager";
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/nix-config";
  };

  programs.home-manager.enable = true;
}
