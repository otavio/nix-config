{ config, pkgs, ... }:
let
  # Flameshot leaves X11 focus following the pointer after its GUI exits
  # (flameshot-org/flameshot#784), which lets the Onboard keyboard steal focus
  # on hover. Restore focus to the prior window unless something else grabbed it.
  flameshotGui = pkgs.writeShellScriptBin "flameshot-gui" ''
    focused="$(${pkgs.xdotool}/bin/xdotool getactivewindow)"
    ${pkgs.flameshot}/bin/flameshot gui "$@"
    status=$?
    if [ "$focused" = "$(${pkgs.xdotool}/bin/xdotool getactivewindow)" ]; then
      ${pkgs.xdotool}/bin/xdotool windowfocus "$focused"
    fi
    exit "$status"
  '';

  flameshotOcrForLang = lang: pkgs.writeScriptBin "flameshot-ocr-${lang}" ''
    # The sleep is required to give time for the fzf-menu to disappear before opening flameshot.
    sleep 0.1

    ${flameshotGui}/bin/flameshot-gui -r | \
       ${pkgs.tesseract}/bin/tesseract -l ${lang} - - | \
       ${pkgs.xclip}/bin/xclip -sel clip
  '';

  flameshotOcr = {
    eng = flameshotOcrForLang "eng";
    por = flameshotOcrForLang "por";
  };
in
{
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        showDesktopNotification = false;
        savePath = "${config.home.homeDirectory}/Downloads";
      };
    };
  };

  home.packages = [
    flameshotGui
    flameshotOcr.eng
    flameshotOcr.por
  ];
}
