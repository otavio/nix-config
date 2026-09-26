{
  imports = [ ./desktop.nix ];
  services = {
    switcherooControl.enable = false;
    libinput.enable = true;
    displayManager = {
      hiddenUsers = [ "otavio" ];

      defaultSession = "cinnamon";
    };
    xserver = {
      enable = true;

      displayManager.lightdm.greeters = {
        slick.enable = true;
        pantheon.enable = false;
      };

      desktopManager.cinnamon.enable = true;
    };
    avahi = {
      enable = true;

      nssmdns4 = true;
    };
    thermald.enable = true;
  };
}
