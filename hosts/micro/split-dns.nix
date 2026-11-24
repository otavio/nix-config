{ lib, ... }:

let
  servers = {
    "intranet.freedom.ind.br" = "192.168.0.240";
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
}
