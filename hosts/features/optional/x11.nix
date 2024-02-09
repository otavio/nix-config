{ pkgs, ... }:

{
  services.xserver = {
    enable = true;

    displayManager.startx.enable = true;

    xkb = {
      variant = "intl";
      model = "pc105";
      layout = "us";
      options = "caps:super";
    };
  };

  programs.xss-lock.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    source-code-pro

    jetbrains-mono
    iosevka-bin

    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
