{ config, pkgs, ... }:

{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      # Cloudflare already validates; local validation turns any DNSSEC-stripping
      # resolver that answers into SERVFAIL for unsigned names under signed TLDs.
      DNSSEC = "no";
      DNSOverTLS = "opportunistic";
      Domains = [ "~." ];
      DNS = [
        "1.1.1.1#cloudflare-dns.com"
        "1.0.0.1#cloudflare-dns.com"
        "2606:4700:4700::1111#cloudflare-dns.com"
        "2606:4700:4700::1001#cloudflare-dns.com"
      ];
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
      Cache = "yes";
      CacheFromLocalhost = "yes";
    };
  };
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.backend = "iwd";
      # NetworkManager marks the uplink as a DNS default route, so resolved
      # races its DHCP-provided resolver against Cloudflare. Keep that resolver
      # for its own search domains only.
      dispatcherScripts = [
        {
          source = pkgs.writeShellScript "dns-no-uplink-default-route" ''
            case "$2" in
              up | dhcp4-change | dhcp6-change | dns-change) ;;
              *) exit 0 ;;
            esac
            ${pkgs.networkmanager}/bin/nmcli -g DEVICE,TYPE,STATE device status |
              while IFS=: read -r dev type state; do
                case "$type:$state" in
                  wifi:connected | ethernet:connected)
                    ${config.systemd.package}/bin/resolvectl default-route "$dev" false
                    ;;
                esac
              done
          '';
        }
      ];
    };
    # Equal-width bands tie on estimated throughput, so 2.4 GHz wins on signal.
    wireless.iwd.settings.Rank.BandModifier5GHz = 1.5;
  };
}
