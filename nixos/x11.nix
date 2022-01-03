{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;

    displayManager.startx.enable = true;
    layout = "us";
    xkbVariant = "intl";
    xkbModel = "pc105";
    xkbOptions = "caps:super";
  };

  programs.xss-lock.enable = true;

  fonts.fonts = with pkgs; [
    font-awesome
    source-code-pro

    jetbrains-mono
    iosevka

    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
