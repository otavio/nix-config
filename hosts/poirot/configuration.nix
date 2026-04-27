{ inputs, flake, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-intel
    common-gpu-nvidia-disable
    common-pc-laptop-ssd
  ] ++ [
    ../features/required

    ../features/optional/anydesk.nix
    ../features/optional/auto-upgrade.nix
    ../features/optional/epson-l495.nix
    ../features/optional/graphical-workstation.nix
    ../features/optional/latest-linux-kernel.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/pt-br-locale.nix
    ../features/optional/quietboot.nix
    ../features/optional/zram-swap.nix

    ../../users/bruna/system
    ../../users/otavio/system

    flake.nixosModules.restic-r2

    ./partitioning.nix
  ];

  my.backup.user = "bruna";

  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager.users = {
    bruna = import ../../users/bruna/home;
    otavio = import ../../users/otavio/home/features/global;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "systemd.gpt_auto=0" ];

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";

  deployment = {
    targetHost = "10.121.15.18";
    buildOnTarget = true;
  };
}
