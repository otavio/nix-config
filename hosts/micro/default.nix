{ inputs, config, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-ssd
  ] ++ [
    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop.nix
    ../features/optional/docker.nix
    ../features/optional/latest-linux-kernel.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/zram-swap.nix

    ./msmtp.nix
    ./partitioning.nix
    ./restic.nix
    ./wireguard.nix
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

  networking.domain = "casa.salvador";

  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager virt-viewer ];

  deployment = {
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}
