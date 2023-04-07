{ config, ... }:
{
  system.autoUpgrade = {
    enable = true;
    dates = "hourly";
    flags = [ "--refresh" ];
    flake = "github:otavio/nix-config";
  };
}
