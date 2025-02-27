{ inputs, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-intel
    common-pc-laptop-ssd
  ] ++ [
    ../features/required

    ../features/optional/anydesk.nix
    ../features/optional/auto-upgrade.nix
    ../features/optional/latest-linux-kernel.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/zram-swap.nix

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
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "pt_BR.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  services.switcherooControl.enable = false;

  services.libinput.enable = true;

  services.displayManager = {
    hiddenUsers = [ "otavio" ];

    defaultSession = "cinnamon";
  };

  services.xserver = {
    enable = true;

    xkb.layout = "br";

    displayManager.lightdm.greeters = {
      slick.enable = true;
      pantheon.enable = false;
    };

    desktopManager.cinnamon.enable = true;
  };

  services.avahi = {
    enable = true;

    nssmdns4 = true;
  };

  hardware.sane = {
    enable = true;

    extraBackends = with pkgs; [
      # EPSON L495
      epkowa
    ];

    netConf = "10.4.0.13";
  };

  services.printing = {
    enable = true;

    drivers = with pkgs; [
      # EPSON L495
      epson-escpr
    ];
  };

  # Enable thermald
  services.thermald.enable = true;

  deployment = {
    targetUser = "otavio";
    targetHost = "10.4.0.51";
    buildOnTarget = true;
  };
}
