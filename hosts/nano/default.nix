{ config, ... }:

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

  hardware.cpu.intel.updateMicrocode = true;
  hardware.video.hidpi.enable = false;

  powerManagement.cpuFreqGovernor = "performance";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.networkmanager.enable = true;

  # Enable fstrim (for SSD disks)
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Enable thermald
  services.thermald.enable = true;

  # Rotate screen as for proper use in GPD Pocket
  services.xserver = {
    videoDrivers = [ "intel" ];
    useGlamor = true;
    xrandrHeads = [
      {
        output = "DSI1";
        primary = true;
        monitorConfig = ''
          Option "Rotate" "right"
        '';
      }
    ];
  };

  deployment = {
    targetHost = "nano.casa.salvador";
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}
