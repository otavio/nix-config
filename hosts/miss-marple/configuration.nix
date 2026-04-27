{ inputs, flake, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-intel
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

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-amd" ];
  };

  deployment = {
    targetHost = "10.4.0.51";
    buildOnTarget = true;
  };
}
