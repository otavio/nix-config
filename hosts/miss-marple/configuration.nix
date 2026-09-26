{ inputs, flake, ... }:

{
  imports =
    with inputs.nixos-hardware.nixosModules;
    [
      common-cpu-intel
      common-gpu-intel
      common-pc-laptop-ssd
    ]
    ++ [
      ../features/required

      ../features/optional/auto-upgrade.nix
      ../features/optional/bluetooth.nix
      ../features/optional/desktop-cinnamon.nix
      ../features/optional/desktop-gnome.nix
      ../features/optional/epson-l495.nix
      ../features/optional/latest-linux-kernel.nix
      ../features/optional/msmtp.nix
      ../features/optional/network-manager.nix
      ../features/optional/no-mitigations.nix
      ../features/optional/parental-controls.nix
      ../features/optional/pipewire.nix
      ../features/optional/pt-br-locale.nix
      ../features/optional/quietboot.nix
      ../features/optional/zram-swap.nix

      ../../users/bruna/system
      ../../users/kadu/system
      ../../users/otavio/system

      flake.nixosModules.restic-r2

      ./partitioning.nix
    ];
  my = {
    backup = {
      user = "bruna";
      prune = true;
    };
    deployment = {
      targetHost = "10.4.0.51";
      buildOnTarget = true;
    };
  };
  services.timekpr.adminUsers = [ "bruna" ];
  home-manager.users = {
    bruna = import ../../users/bruna/home;
    kadu = import ../../users/kadu/home;
    otavio = import ../../users/otavio/home/features/global;
  };
  boot = {
    loader.systemd-boot.enable = true;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
  };
}
