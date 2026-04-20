{
  services.switcherooControl.enable = false;

  services.libinput.enable = true;

  services.displayManager = {
    hiddenUsers = [ "otavio" ];

    defaultSession = "cinnamon";
  };

  services.xserver = {
    enable = true;

    xkb.layout = "br";

    displayManager.lightdm.greeters = {
      slick.enable = true;
      pantheon.enable = false;
    };

    desktopManager.cinnamon.enable = true;
  };

  services.avahi = {
    enable = true;

    nssmdns4 = true;
  };

  services.thermald.enable = true;
}
