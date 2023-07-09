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

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR
  ];
}
