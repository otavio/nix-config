{ lib, ... }:

{
  console = {
    font = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "br-latin1-us";
  };
}
