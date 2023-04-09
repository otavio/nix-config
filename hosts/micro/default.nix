{ config, pkgs, ... }:

{
  imports = [
    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop.nix
    ../features/optional/docker.nix
    ../features/optional/latest-linux-kernel.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/zram-swap.nix

    ./msmtp.nix
    ./partitioning.nix
    ./restic.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "video=HDMI-A-1:2560x1080" ];
    extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
    extraModprobeConfig = ''
      blacklist rtw88_8822bu
      options 88x2bu rtw_drv_log_level=1 rtw_led_ctrl=1 rtw_vht_enable=1 rtw_switch_usb_mode=0
    '';
  };

  hardware.cpu.intel.updateMicrocode = true;
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

  services.resolved.enable = true;
  networking.useDHCP = false;
  networking.domain = "casa.salvador";

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi.backend = "iwd";
  };

  # Enable Fireguard
  sops.secrets."wireguard/micro/private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.10.1.3/32" ];
      privateKeyFile = config.sops.secrets."wireguard/micro/private-key".path;
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

  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager virt-viewer ];

  deployment = {
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}
