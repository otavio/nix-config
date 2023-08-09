{ config, ... }:

{
  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # Refs: https://github.com/NixOS/nixpkgs/issues/180175
  networking.networkmanager.unmanaged = [ "wg0" ];
  systemd.network.wait-online.enable = false;

  sops.secrets."wireguard/micro/private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.10.1.3/32" ];
      privateKeyFile = config.sops.secrets."wireguard/micro/private-key".path;
      peers = [
        {
          publicKey = "3cJEElR2e9ClzNHHqDkNgqulOsw3u5OdKnKj3bd4K1c=";
          allowedIPs = [
            "10.4.0.0/16"
            "10.5.0.0/16"
          ];
          endpoint = "ossystems.ddns.net:51820";
          persistentKeepalive = 25;
          dynamicEndpointRefreshSeconds = 30;
        }
      ];
      postSetup = ''
        resolvectl dns    wg0 10.5.1.254
        resolvectl domain wg0 "~lab.ossystems"
        resolvectl dnssec wg0 false
      '';
    };
  };
}
