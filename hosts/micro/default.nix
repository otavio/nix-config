{ config, inputs, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-cpu-amd-pstate
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
    ../features/optional/polkit.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/zram-swap.nix

    ./aichat.nix
    ./msmtp.nix
    ./partitioning.nix
    ./restic.nix
    ./zerotier.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "video=HDMI-A-1:2560x1080" ];
    extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
    extraModprobeConfig = ''
      blacklist rtw88_8822bu
      options 88x2bu rtw_drv_log_level=1 rtw_led_ctrl=1 rtw_vht_enable=1 rtw_switch_usb_mode=0
    '';
  };

  services.udev.extraRules = ''
    # Set scheduler for NVMe
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # Set scheduler for SSD and eMMC
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    # Set scheduler for rotating disks
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

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
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    cntr
  ];

  deployment = {
    targetUser = "otavio";
    allowLocalDeployment = true;
  };
}
