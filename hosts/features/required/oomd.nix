{ lib, ... }:

{
  systemd.oomd = {
    enable = lib.mkDefault true;
    enableSystemSlice = lib.mkDefault true;
    enableUserSlices = lib.mkDefault true;

    # Swap-based killing is counterproductive with zram swap (compressed RAM),
    # so stay on PSI memory-pressure kills only.
    enableRootSlice = lib.mkDefault false;
  };
}
