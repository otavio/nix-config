{ config, pkgs, ... }:
let
  flameshotOcrForLang = lang: pkgs.writeScriptBin "flameshot-ocr-${lang}" ''
    # The sleep is required to give time for the fzf-menu to disappear before opening flameshot.
    sleep 0.1

    ${pkgs.flameshot}/bin/flameshot gui -r | \
       ${pkgs.tesseract}/bin/tesseract -l ${lang} - - | \
       ${pkgs.xclip}/bin/xclip -sel clip
  '';

  flameshotOcr = {
    eng = flameshotOcrForLang "eng";
    por = flameshotOcrForLang "por";
  };

  flameshot = pkgs.libsForQt5.callPackage ./flameshot.nix { };
in
{
  services.flameshot = {
    enable = true;
    package = flameshot;
    settings = {
      General = {
        disabledTrayIcon = true;
        showDesktopNotification = false;
        savePath = "${config.home.homeDirectory}/Downloads";
      };
    };
  };

  home.packages = [
    flameshotOcr.eng
    flameshotOcr.por
  ];
}
