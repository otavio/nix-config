{ config, inputs, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd-pstate
    common-gpu-amd-sea-islands
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
    ../features/optional/zram-swap.nix

    ./aichat.nix
    ./msmtp.nix
    ./partitioning.nix
    ./restic.nix
    ./zerotier.nix
    ./wireguard.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-amd" ];
  };

  services.udev.extraRules = ''
    # Set scheduler for NVMe
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # Set scheduler for SSD and eMMC
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    # Set scheduler for rotating disks
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

    # Keystone 3 Pro
    ATTRS{idVendor}=="1209", ATTRS{idProduct}=="3001", MODE:="0666", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
  '';

  networking.domain = "casa.salvador";

  security.pam.services.swaylock = { };

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
