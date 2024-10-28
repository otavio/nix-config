{ inputs, lib, config, ... }:
{
  nix = {
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
        "https://otavio-nix-config.cachix.org"
        "https://numtide.cachix.org"
      ];

      # Caches in trusted-substituters can be used by unprivileged users i.e. in
      # flakes but are not enabled by default.
      trusted-substituters = config.nix.settings.substituters;

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "otavio-nix-config.cachix.org-1:4HXl0KPGJ0+tkTUn/0tHRpz1wJst9MxovLjKbsPnqS4="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];

      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };

    # improve desktop responsiveness when updating the system
    daemonCPUSchedPolicy = "idle";

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      # Delete older generations too
      options = "--delete-older-than 7d";
    };

    # Add each flake input as a registry
    # To make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Map registries to channels
    # Very useful when using legacy commands
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };
}
