{ pkgs, ... }:
{
  systemd.services.anydesk = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    requires = [ "network.target" ];
    description = "AnyDesk";
    serviceConfig = {
      Type = "simple";
      User = "root";
      ExecStart = ''
        ${pkgs.anydesk}/bin/anydesk --service
      '';
      Restart = "on-failure";
      RestartSec = 5;
      StartLimitBurst = 3;
      StartLimitInterval = 10;
      TimeoutStopSec = 30;
      LimitNOFILE = 100000;
      PIDFile = /var/run/anydesk.pid;
      KillMode = "mixed";
    };
  };
}
