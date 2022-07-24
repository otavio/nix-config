{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../common
    ../common/zram-swap.nix
    ../common/bluetooth.nix
    ../common/desktop.nix
    ../common/udev.nix
    ../common/x11.nix
  ];

  boot.kernelParams = [ "video=HDMI-A-1:2560x1080" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.video.hidpi.enable = false;
  hardware.enableRedistributableFirmware = true;

  services.xserver = {
    xrandrHeads = [{
      output = "HDMI-1";
      primary = true;
      monitorConfig = ''
        Modeline "2560x1080_60.00"  230.76  2560 2728 3000 3440  1080 1081 1084 1118  -HSync +Vsync
        Option "PreferredMode" "2560x1080"
        Option "Position" "0 0"
      '';
    }];
    resolutions = [{
      x = 2560;
      y = 1080;
    }];
  };

  networking.useDHCP = false;

  networking.networkmanager.enable = true;

  # Enable fstrim (for SSD disks)
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Enable thermald
  services.thermald.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager virt-viewer ];

  deployment = {
    targetHost = "micro.casa.salvador";
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}
