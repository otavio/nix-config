{ inputs, flake, lib, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd-pstate
    common-gpu-amd-sea-islands
    common-pc-ssd
  ] ++ [
    ../features/required

    ../features/optional/bluetooth.nix
    ../features/optional/desktop-i3.nix
    ../features/optional/docker.nix
    ../features/optional/latest-linux-kernel.nix
    ../features/optional/network-manager.nix
    ../features/optional/nix-ld.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/voice-coding.nix
    ../features/optional/zram-swap.nix

    ../../users/otavio/system

    flake.nixosModules.restic-r2

    ./msmtp.nix
    ./partitioning.nix
    ./whisrs.nix
    ./wireguard.nix
  ];

  my.backup = {
    user = "otavio";
    extraExcludes = [
      "--exclude='.direnv'"
      "--exclude='target'"
      "--exclude='build*/**/tmp'"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager.users.otavio = import ../../users/otavio/home/micro.nix;

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

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Wrap in a zsh login shell so /etc/profile and the user's zprofile
        # are sourced — without that, the X session inherits only greetd's
        # bare PAM-session PATH and i3 can't find alacritty /
        # i3-sensible-terminal / fzf / pa-applet (all in
        # /etc/profiles/per-user/$USER/bin).
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd '${pkgs.zsh}/bin/zsh -lc startx'";
        user = "greeter";
      };
    };
  };

  security.pam.services.swaylock = { };
  security.polkit.enable = true;

  networking.firewall.trustedInterfaces = [ "virbr0" ];
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    cntr
  ];

  deployment.allowLocalDeployment = true;

  # VM-only overrides for `nixos-rebuild build-vm --flake .#micro`. The real
  # boot sees neither these settings nor the sops secret stub.
  virtualisation.vmVariant = {
    services.btrfs.autoScrub.enable = lib.mkForce false;
    networking.wireguard.interfaces = lib.mkForce { };
    programs.msmtp.accounts = lib.mkForce { };
    services.restic.backups = lib.mkForce { };
    sops.secrets = lib.mkForce { };
    systemd.tmpfiles.rules = [
      "f /run/secrets/openai_api_key 0400 otavio users - sk-vm-dummy"
    ];
    users.users.otavio.password = lib.mkForce "vm";
    services.getty.autologinUser = lib.mkForce "otavio";

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
      settings.PermitRootLogin = "no";
    };
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];
  };
}
