{
  boot.swraid.enable = false;
  services.btrfs.autoScrub.enable = true;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ADATA_IM2S3338-128GD2_5J4220001138";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
              };
            };
            boot = {
              label = "boot";
              start = "0";
              end = "1M";
              type = "EF02"; # for grub MBR
            };
            root = {
              label = "root";
              start = "512M";
              end = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
