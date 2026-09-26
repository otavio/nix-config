{
  pkgs,
  modulesPath,
  targetConfiguration,
  ...
}:

{
  imports = [
    ../../hosts/features/required

    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];
  isoImage = {
    compressImage = false;
    squashfsCompression = "zstd -Xcompression-level 1";
  };
  boot = {
    # Disable ZFS support, it may not be compatible
    # with the configured kernel version
    supportedFilesystems = pkgs.lib.mkForce [
      "btrfs"
      "reiserfs"
      "vfat"
      "f2fs"
      "xfs"
      "ntfs"
      "cifs"
    ];
    swraid = {
      enable = true;
      # remove warning about unset mail
      mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
    };
  };
  networking = {
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    networkmanager.enable = true;
  };
  # Allow root login
  services.openssh.settings.PermitRootLogin = pkgs.lib.mkForce "without-password";
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
