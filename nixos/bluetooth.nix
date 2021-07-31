{ config, pkgs, ... }:

{
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;

    extraModules = [ pkgs.pulseaudio-modules-bt ];
    extraConfig = ''
      load-module module-switch-on-connect
    '';
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
}
