{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../common
    ../common/zram-swap.nix
  ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.grub.device = "nodev";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "pt_BR.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  services.xserver = {
    enable = true;

    layout = "br";

    libinput.enable = true;

    displayManager = {
      hiddenUsers = [ "otavio" ];
      defaultSession = "cinnamon";

      lightdm.greeters.pantheon.enable = true;
    };

    desktopManager.cinnamon.enable = true;
  };

  services.printing = {
    enable = true;

    drivers = with pkgs; [
      # EPSON L495
      hplip
    ];
  };

  # Enable thermald
  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
    libreoffice
  ];
}
