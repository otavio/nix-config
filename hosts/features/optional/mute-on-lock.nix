{ lib, pkgs, ... }:

let
  mute-on-lock = pkgs.writeShellApplication {
    name = "mute-on-lock";
    runtimeInputs = with pkgs; [
      coreutils
      dbus
      gnugrep
      wireplumber
    ];
    text = ''
      # Only unmute on unlock if the mute was ours, so a manual mute survives.
      flag="$XDG_RUNTIME_DIR/mute-on-lock"

      dbus-monitor --session \
        "type='signal',interface='org.cinnamon.ScreenSaver',member='ActiveChanged'" \
        "type='signal',interface='org.gnome.ScreenSaver',member='ActiveChanged'" |
        while read -r line; do
          case "$line" in
            "boolean true")
              if ! wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
                touch "$flag"
              fi
              ;;
            "boolean false")
              if [ -e "$flag" ]; then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
                rm -f "$flag"
              fi
              ;;
          esac
        done
    '';
  };
in
{
  systemd.user.services.mute-on-lock = {
    description = "Mute audio while the screen is locked";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = lib.getExe mute-on-lock;
      Restart = "on-failure";
    };
  };
}
