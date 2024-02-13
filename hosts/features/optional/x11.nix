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
}
