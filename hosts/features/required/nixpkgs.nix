{ flake, ... }:

{
  nixpkgs = {
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowUnfree = true;
    };
  };
}
