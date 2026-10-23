{ config, lib, ... }:

let
  servers = {
    "intranet.freedom.ind.br" = "192.168.0.233";
    "lab.ossystems" = "10.5.3.1";
  };
in
{
  # resolved only routes queries to links holding a global address, so each
  # dummy link gets an unused TEST-NET one.
  networking.networkmanager.ensureProfiles.profiles = lib.listToAttrs (
    lib.imap0 (i: domain: rec {
      name = "dns${toString i}";
      value = {
        connection = {
          id = name;
          type = "dummy";
          interface-name = name;
          dns-over-tls = 0;
        };
        ipv4 = {
          method = "manual";
          address1 = "192.0.2.${toString (i + 1)}/32";
          never-default = true;
          dns = "${servers.${domain}};";
          dns-search = "~${domain};";
        };
        ipv6.method = "disabled";
      };
    }) (lib.attrNames servers)
  );

  # The private zones are unsigned, so DNSSEC validation would reject them.
  environment.etc."dnssec-trust-anchors.d/private.negative".text = lib.concatLines (
    lib.attrNames servers
  );
  systemd.services.systemd-resolved.restartTriggers = [
    config.environment.etc."dnssec-trust-anchors.d/private.negative".source
  ];
}
