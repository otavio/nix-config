{ pkgs, modulesPath, targetConfiguration, ... }:

{
  imports = [
    ../features/required

    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  isoImage = {
    compressImage = false;
    squashfsCompression = "zstd -Xcompression-level 1";
  };

  # Disable ZFS support, it may not be compatible
  # with the configured kernel version
  boot.supportedFilesystems = pkgs.lib.mkForce
    [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  boot.swraid.enable = true;
  # remove warning about unset mail
  boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Allow root login
  services.openssh.settings.PermitRootLogin = pkgs.lib.mkForce "without-password";

  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  disko.enableConfig = false;
  environment.systemPackages =
    let
      cfg = targetConfiguration.config.system.build;

      disko = pkgs.writeShellScriptBin "disko" "${cfg.diskoScript}";
      disko-mount = pkgs.writeShellScriptBin "disko-mount" "${cfg.mountScript}";
      disko-format = pkgs.writeShellScriptBin "disko-format" "${cfg.formatScript}";
      install-system = pkgs.writeShellScriptBin "install-system" ''
        set -euo pipefail

        echo "Formatting disks..."
        disko-format

        echo "Mounting disks..."
        disko-mount

        echo "Installing system..."
        ${cfg.nixos-install}/bin/nixos-install \
          --root /mnt \
          --no-root-passwd \
          --no-channel-copy \
          --system ${cfg.toplevel}

        echo "Shutting off..."
        ${pkgs.systemd}/bin/shutdown now
      '';
    in
    [
      pkgs.git
      pkgs.zile

      disko
      disko-mount
      disko-format
      install-system
    ];
}
