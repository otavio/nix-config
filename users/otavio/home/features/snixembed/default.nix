{ lib, ... }:

{
  services.snixembed = {
    enable = true;
    beforeUnits = [ "tray.target" ];
  };

  # Type=dbus holds the unit in "activating" until snixembed has claimed the
  # watcher name, so consumers ordered after tray.target find a tray that can
  # actually accept icons. Under Type=simple the target is reached as soon as
  # the process forks.
  systemd.user.services.snixembed = {
    Unit = {
      After = [ "dbus.service" ];
      PartOf = lib.mkForce [ ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.kde.StatusNotifierWatcher";
    };
    Install.WantedBy = [ "tray.target" ];
  };
}
