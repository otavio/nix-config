{
  hardware.graphics.enable = true;
  programs.dconf.enable = true;
  services = {
    gnome = {
      gnome-keyring.enable = true;
      gcr-ssh-agent.enable = false;
    };
  };
}
