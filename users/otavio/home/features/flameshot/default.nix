{ pkgs, ... }:

{
  services.flameshot.enable = true;

  home.packages = with pkgs; [
    flameshotOcr.eng
    flameshotOcr.por
  ];
}
