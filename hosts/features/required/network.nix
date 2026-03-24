{
  # Avoid using the ISC-DHCP as we need to use systemd anyway; this reduce memory footprint.
  networking = {
    useNetworkd = true;

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # Refs: https://github.com/NixOS/nixpkgs/issues/180175
  systemd.network.wait-online.enable = false;
}
