# This file holds config that i use on all hosts
{ lib, config, pkgs, system, inputs, ... }:
{
  imports = [
    ./locale.nix
    ./nix.nix
    ./openssh.nix
    ./upgrade-diff.nix
  ];

  system.stateVersion = "22.05";

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

  security.sudo.wheelNeedsPassword = false;

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
}