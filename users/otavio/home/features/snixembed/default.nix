{ lib, ... }:

{
  services.snixembed.enable = true;

  systemd.user.services.snixembed.Unit = {
    After = lib.mkForce [ "dbus.service" ];
    PartOf = lib.mkForce [ ];
  };
}
