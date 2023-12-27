{
  boot.swraid.enable = false;

  disko.devices = {
    disk.primary = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "ESP";
            start = "1MiB";
            end = "512MiB";
            fs-type = "fat32";
            part-type = "primary";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "root";
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
          }
        ];
      };
    };
  };
}
