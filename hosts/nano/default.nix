{ config, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/zram-swap.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  hardware.cpu.intel.updateMicrocode = true;

  powerManagement.cpuFreqGovernor = "performance";

  services.resolved.enable = true;
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi.backend = "iwd";
  };

  # Enable WireGuard
  sops.secrets."wireguard/nano/private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.10.1.2/32" ];
      privateKeyFile = config.sops.secrets."wireguard/nano/private-key".path;

      peers = [
        {
          publicKey = "3cJEElR2e9ClzNHHqDkNgqulOsw3u5OdKnKj3bd4K1c=";
          allowedIPs = [
            "10.4.0.0/16"
            "10.5.0.0/16"
          ];
          endpoint = "ossystems.ddns.net:51820";
          persistentKeepalive = 25;
          dynamicEndpointRefreshSeconds = 30;
        }
      ];
      postSetup = ''
        resolvectl dns    wg0 10.5.1.254
        resolvectl domain wg0 "~lab.ossystems"
        resolvectl dnssec wg0 false
      '';
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
    targetUser = "otavio";
    targetHost = "10.4.0.117";
    allowLocalDeployment = true;
  };
}

