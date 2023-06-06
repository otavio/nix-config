{ config, pkgs, ... }:
let
  irssiWrapper = pkgs.writeScriptBin "irssi" ''
    export LIBERACHAT_PASSWORD=$(${pkgs.sops}/bin/sops --decrypt --extract '["irssi-nickserv"]' $HOME/nix-config/secrets/secrets.yaml)
    ${pkgs.irssi}/bin/irssi
  '';
in
{
  xdg.enable = true;

  # We force the override so we workaround the error below:
  #   Existing file '/.../.config/mimeapps.list' is in the way of
  #   '/nix/store/...-home-manager-files/.config/mimeapps.list'
  # Issue: https://github.com/nix-community/home-manager/issues/1213
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  home.packages =
    let
      flameshotOcrForLang = lang: pkgs.writeScriptBin "flameshot-ocr-${lang}" ''
        # The sleep is required to give time for the fzf-menu to disappear before opening flameshot.
        sleep 0.1

        ${pkgs.flameshot}/bin/flameshot gui -r | \
           ${pkgs.tesseract}/bin/tesseract -l ${lang} - - | \
           ${pkgs.xclip}/bin/xclip -sel clip
      '';
    in
    with pkgs; [
      (flameshotOcrForLang "eng")
      (flameshotOcrForLang "por")

      anydesk
      discord
      gthumb
      irssiWrapper
      tdesktop
      nixpkgs-fmt
      nixpkgs-review
      obsidian
      pavucontrol
      scrcpy
      skypeforlinux
      slack
    ];

  services.unclutter.enable = true;

  services.parcellite.enable = true;
  xdg.configFile."parcellite/parcelliterc".source =
    ./parcellite/parcelliterc;

  programs.alacritty = {
    enable = true;
    settings = {
      env.term = "alacritty";
    };
  };

  programs.zathura.enable = true;

  services.dunst.enable = true;
  xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;
  xdg.configFile."dunst/skype".source = ./dunst/skype;

  services.flameshot.enable = true;

  home.file.".irssi" = {
    source = ./irssi;
    recursive = true;
  };

  programs.brave.enable = true;
}
