{ config, pkgs, ... }:

{
  zramSwap = {
    enable = true;
    memoryPercent = 40;
    numDevices = 1;
    priority = 10;
  };
}
