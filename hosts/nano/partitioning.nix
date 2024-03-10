{
  boot.swraid.enable = false;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk1";
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
                mountpoint = "/boot";
              };
            };
            root = {
              label = "root";
              start = "512M";
              end = "-8G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            swap = {
              label = "swap";
              start = "-8G";
              end = "100%";
              content = { type = "swap"; };
            };
          };
        };
      };
    };
  };
}
