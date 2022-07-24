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

  services.resolved.enable = true;
  networking.useDHCP = false;
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi.backend = "iwd";
  };

  # Enable WireGuard
  sops.secrets.nano-wireguard-private-key = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.10.1.2/32" ];
      privateKeyFile = config.sops.secrets.nano-wireguard-private-key.path;

      peers = [
        {
          publicKey = "3cJEElR2e9ClzNHHqDkNgqulOsw3u5OdKnKj3bd4K1c=";
          allowedIPs = [
            "10.4.0.0/16"
            "10.5.0.0/16"
          ];
          endpoint = "ossystems.ddns.net:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

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

    dpi = 140;
  };

  deployment = {
    targetHost = "nano.casa.salvador";
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}

