{ config, pkgs, ... }:

{
  services.pipewire = {
    enable = true;

    # Compatibility shims, adjust according to your needs
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
}
