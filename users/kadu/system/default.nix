{ config, ... }:

let
  user = config.users.users.kadu;
in
{
  users.users.kadu = {
    description = "Kadu Borba";

    isNormalUser = true;
    extraGroups = [ ];

    uid = 1003;

    # Default - used for bootstrapping.
    password = "pw";
  };

  # The host default session is Cinnamon and there is no per-user option for
  # it, so the choice has to be pushed into AccountsService. LightDM resets
  # every user to the host default as it starts, which means this has to run
  # after the greeter is up, and the write only sticks once LightDM has settled
  # -- hence the retry rather than a single call.
  systemd.services.kadu-session = {
    description = "Select the GNOME session for ${user.name}";

    after = [ "accounts-daemon.service" "display-manager.service" ];
    requires = [ "accounts-daemon.service" ];
    wantedBy = [ "graphical.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script =
      let
        object = "org.freedesktop.Accounts /org/freedesktop/Accounts/User${toString user.uid} org.freedesktop.Accounts.User";
        busctl = "${config.systemd.package}/bin/busctl";
      in
      ''
        for _ in $(seq 1 30); do
          ${busctl} call ${object} SetSession s gnome
          ${busctl} call ${object} SetSessionType s wayland
          ${busctl} call ${object} SetXSession s gnome

          sleep 2

          if [ "$(${busctl} get-property ${object} Session)" = 's "gnome"' ]; then
            exit 0
          fi
        done

        echo "gnome session did not stick for ${user.name}" >&2
        exit 1
      '';
  };
}
