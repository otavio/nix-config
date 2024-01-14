{
  boot.swraid.enable = false;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk1";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "root";
              start = "512M";
              end = "-8G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
            {
              name = "swap";
              start = "-8G";
              end = "100%";
              content = { type = "swap"; };
            }
            {
              name = "ESP";
              start = "1M";
              end = "512M";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
          ];
        };
      };
    };
  };
}
