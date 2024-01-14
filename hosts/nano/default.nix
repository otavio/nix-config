{ inputs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-gpu-intel
    common-pc-laptop-ssd
  ] ++ [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/zram-swap.nix

    ./zerotier.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # Enable fstrim (for SSD disks)
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Enable thermald
  services.thermald.enable = true;

  # Rotate screen as for proper use in GPD Pocket
  services.xserver = {
    videoDrivers = [ "intel" ];
    xrandrHeads = [
      {
        output = "DSI1";
        primary = true;
        monitorConfig = ''
          Option "Rotate" "right"
        '';
      }
    ];

    dpi = 140;
  };

  deployment = {
    targetUser = "otavio";
    targetHost = "10.4.0.31";
    allowLocalDeployment = true;
  };
}

