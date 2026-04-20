{ pkgs, ... }:

{
  hardware.sane = {
    enable = true;

    extraBackends = with pkgs; [
      epkowa
    ];

    netConf = "10.4.0.13";
  };

  services.printing = {
    enable = true;

    drivers = with pkgs; [
      epson-escpr
    ];
  };
}
