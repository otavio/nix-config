{ inputs, lib, config, outputs, ... }:

{
  nixpkgs = {
    overlays = [
      inputs.talon-nix.overlays.default
    ] ++ (builtins.attrValues outputs.overlays);

    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = lib.mkDefault "otavio";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
  };
}
