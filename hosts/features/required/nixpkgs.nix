{ flake, lib, ... }:

{
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowUnfree = true;
    };
  };
}
