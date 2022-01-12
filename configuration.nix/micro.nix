{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    <home-manager/nixos>

    ../nixos/base.nix
    ../nixos/zram-swap.nix
    ../nixos/bluetooth.nix
    ../nixos/desktop.nix
    ../nixos/udev.nix
    ../nixos/x11.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "video=HDMI-A-1:2560x1080" ];
  };

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

  powerManagement.cpuFreqGovernor = "performance";

  networking.hostName = "micro"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-latin1-us";
  };

  # Enable fstrim (for SSD disks)
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Enable thermald
  services.thermald.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    forwardX11 = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager virt-viewer ];

  nixpkgs.config.allowUnfree = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
