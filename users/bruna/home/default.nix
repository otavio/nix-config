{ lib, config, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = lib.mkDefault "bruna";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
  };
}
