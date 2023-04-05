# This file holds config that i use on all hosts
{ lib, config, pkgs, system, inputs, ... }:
{
  imports = [
    ./upgrade-diff.nix
  ];

  system.stateVersion = "22.05";

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  console = {
    font = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "br-latin1-us";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    tmpOnTmpfs = true;

    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_priority=3"
      "vt.global_cursor_default=0"
      "vga=current"
      "mitigations=off" # turn off mitigations so we gain some performance
      "fsck.repair=yes"
    ];

    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  nix = {
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };

    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      warn-dirty = false
    '';

    nixPath = [
      "nixpkgs=/etc/nix/channels/nixpkgs"
      "home-manager=/etc/nix/channels/home-manager"
    ];

    gc = {
      automatic = true;
      dates = "daily";
    };

    optimise.automatic = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
}
