{ pkgs }:
let
  flameshotOcrForLang = lang: pkgs.writeScriptBin "flameshot-ocr-${lang}" ''
    # The sleep is required to give time for the fzf-menu to disappear before opening flameshot.
    sleep 0.1

    ${pkgs.flameshot}/bin/flameshot gui -r | \
       ${pkgs.tesseract}/bin/tesseract -l ${lang} - - | \
       ${pkgs.xclip}/bin/xclip -sel clip
  '';
in
{
  flameshotOcr = {
    eng = flameshotOcrForLang "eng";
    por = flameshotOcrForLang "por";
  };

  base16-shell = pkgs.callPackage ./base16-shell { };
  bitbake-completion = pkgs.callPackage ./bitbake-completion { };
  mods = pkgs.callPackage ./mods { };
  kube-ps1 = pkgs.callPackage ./kube-ps1 { };
  pa-applet = pkgs.callPackage ./pa-applet { };
  patman = pkgs.callPackage ./patman { };
}
