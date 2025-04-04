{ inputs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-laptop-ssd
  ] ++ [
    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/zram-swap.nix

    ./partitioning.nix
    ./zerotier.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_acpi" ];
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      # The GPD Pocket uses a tablet OLED display, that is mounted rotated 90° counter-clockwise
      "fbcon=rotate:1"
      "video=DSI-1:panel_orientation=right_side_up"
    ];
  };

  # Enable fstrim (for SSD disks)
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Enable thermald
  services.thermald.enable = true;

  deployment = {
    targetUser = "otavio";
    targetHost = "10.4.0.31";
    allowLocalDeployment = true;
  };
}

