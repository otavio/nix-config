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
              start = "0";
              end = "1M";
              flags = [ "bios_grub" ];
            }
            {
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
