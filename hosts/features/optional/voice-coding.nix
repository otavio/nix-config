{ inputs, ... }:

{
  imports = [ inputs.talon-nix.nixosModules.talon ];

  nixpkgs.overlays = [
    inputs.talon-nix.overlays.default
  ];

  programs.talon.enable = true;
}
