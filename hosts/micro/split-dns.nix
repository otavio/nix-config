{ config, lib, ... }:

let
  servers = {
    "intranet.freedom.ind.br" = "192.168.0.233";
    "lab.ossystems" = "10.5.3.1";
  };
in
{
  # Delegates rather than link-scoped servers: resolved pins a link's UDP
  # queries to that interface, so they never reach the tunnel routing them.
  services.resolved.dnsDelegates = lib.mapAttrs' (
    domain: server:
    lib.nameValuePair (lib.replaceStrings [ "." ] [ "-" ] domain) {
      Delegate = {
        DNS = server;
        Domains = domain;
      };
    }
  ) servers;

  # The private zones are unsigned, so DNSSEC validation would reject them.
  environment.etc."dnssec-trust-anchors.d/private.negative".text = lib.concatLines (
    lib.attrNames servers
  );
  systemd.services.systemd-resolved.restartTriggers = [
    config.environment.etc."dnssec-trust-anchors.d/private.negative".source
  ];
}
