{
  virtualisation.docker = {
    enable = true;
  };

  # Container veth link-local churn triggers ERR_NETWORK_CHANGED in Chromium.
  boot.kernel.sysctl."net.ipv6.conf.default.addr_gen_mode" = 1;
}
