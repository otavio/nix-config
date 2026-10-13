{
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings.default-address-pools = [
        {
          base = "172.16.0.0/12";
          size = 24;
        }
      ];
    };
  };

  # Container veth link-local churn triggers ERR_NETWORK_CHANGED in Chromium.
  boot.kernel.sysctl."net.ipv6.conf.default.addr_gen_mode" = 1;
}
