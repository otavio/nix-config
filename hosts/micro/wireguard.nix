{ config, ... }:

{
  sops.secrets."wireguard/micro/private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "192.168.240.2/32" ];
      privateKeyFile = config.sops.secrets."wireguard/micro/private-key".path;

      peers = [
        {
          publicKey = "hU9doVYJNhCqNCVbWege7fKD9o52/jPDS6dMClUZzCw=";
          allowedIPs = [ "192.168.0.0/23" ];
          endpoint = "hfm09v4k9nk.sn.mynetname.net:13231";
          persistentKeepalive = 25;
          dynamicEndpointRefreshSeconds = 30;
        }
      ];
      postSetup = ''
        resolvectl dns    wg0 192.168.0.233
        resolvectl domain wg0 "~intranet.freedom.ind.br"
        resolvectl dnssec wg0 false
      '';
    };
  };
}
