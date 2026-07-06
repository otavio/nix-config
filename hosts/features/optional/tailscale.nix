{ config, ... }:

{
  services.tailscale.enable = true;

  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}
