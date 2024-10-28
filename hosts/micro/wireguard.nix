{ config, ... }:

{
  sops.secrets."wireguard/micro/private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "192.168.240.3/32" ];

      privateKeyFile = config.sops.secrets."wireguard/micro/private-key".path;

      peers = [
        {
          publicKey = "o1jZWNTlnZD50WwtATXWS/QDxuijQ9kyJxQODJp0bGo=";
          allowedIPs = [ "192.168.0.0/24" ];
          endpoint = "8aff0aba023e.sn.mynetname.net:13231";
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
