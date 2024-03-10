{
  boot.swraid.enable = false;
  services.btrfs.autoScrub.enable = true;

  disko.devices = {
    disk.primary = {
      type = "disk";
      device = "/dev/disk/by-diskseq/1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "ESP";
            start = "1MiB";
            end = "512MiB";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            label = "root";
            start = "512MiB";
            end = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
