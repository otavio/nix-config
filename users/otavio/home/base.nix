{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tree
    xclip

    nettools # for ifconfig
    psmisc # for killall
  ];
}
