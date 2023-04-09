{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ADATA_IM2S3338-128GD2_5J4220001138";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              type = "partition";
              name = "ESP";
              start = "1M";
              end = "512M";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
              };
            }
            {
              name = "boot";
              type = "partition";
              start = "0";
              end = "1M";
              flags = [ "bios_grub" ];
            }
            {
              type = "partition";
              name = "root";
              start = "512M";
              end = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
              };
            }
          ];
        };
      };
    };
  };
}
