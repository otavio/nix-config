# This file holds config that i use on all hosts
{ lib, config, pkgs, system, inputs, ... }:
let
  inherit (lib) mkDefault;
in
{
  system.stateVersion = "22.05";

  i18n.defaultLocale = pkgs.lib.mkDefault "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  console = {
    font = mkDefault "Lat2-Terminus16";
    keyMap = mkDefault "br-latin1-us";
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;

    tmpOnTmpfs = true;

    kernelParams = [
      "quiet"
      "udev.log_priority=3"
      "vt.global_cursor_default=0"
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
      experimental-features = nix-command flakes
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

  environment = {
    etc = {
      "nix/channels/nixpkgs".source = inputs.nixpkgs;
      "nix/channels/home-manager".source = inputs.home-manager;
    };
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    forwardX11 = true;
  };

  security.sudo.wheelNeedsPassword = false;

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
}
