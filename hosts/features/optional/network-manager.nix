{
  services.resolved.enable = true;
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi.backend = "iwd";
  };
}
