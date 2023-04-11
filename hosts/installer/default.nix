{ config, pkgs, modulesPath, targetConfiguration, ... }:

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

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  disko.enableConfig = false;
  environment.systemPackages = with pkgs; [
    zile

    (writeShellScriptBin "nixos-do-install" ''
      set -eux

      ${targetConfiguration.config.system.build.diskoNoDeps} --mode zap_create_mount

      ${config.system.build.nixos-install}/bin/nixos-install \
          --root /mnt \
          --no-root-passwd \
          --no-channel-copy \
          --system ${targetConfiguration.config.system.build.toplevel}

      echo "Syncing filesystems"

      sync

      echo "Shutting off..."
      ${systemd}/bin/shutdown now
    '')
  ];
}
