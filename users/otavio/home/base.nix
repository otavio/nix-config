{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gping
    htop
    mtr
    nnn
    tree
    xclip

    axel
    wget
    nettools # for ifconfig
    psmisc # for killall
  ];
}
