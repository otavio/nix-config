{ config, lib, pkgs, ... }:

let
  cfg = config.my.backup;
  resticBin = lib.getExe config.services.restic.backups.r2.package;

  alert = pkgs.writeShellScript "backup-alert" ''
    unit="$1"
    {
      echo "To: ${cfg.alertTo}"
      echo "Subject: [${config.networking.hostName}] backup problem: $unit"
      echo
      ${pkgs.systemd}/bin/systemctl status --full --no-pager "$unit" 2>&1 || true
      echo
      ${pkgs.systemd}/bin/journalctl -u "$unit" -n 60 --no-pager 2>&1 || true
    } | ${pkgs.msmtp}/bin/msmtp --read-recipients
  '';

  freshness = pkgs.writeShellScript "backup-freshness" ''
    set -uo pipefail

    latest=$(${resticBin} snapshots --json --latest 1 \
      --host ${config.networking.hostName} 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.[0].time // empty')

    if [ -z "$latest" ]; then
      echo "no snapshot found for this host" >&2
      exit 1
    fi

    age=$(( ($(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/date -d "$latest" +%s)) / 86400 ))
    echo "latest snapshot: $latest (''${age}d old)"

    if [ "$age" -gt ${toString cfg.maxAgeDays} ]; then
      echo "older than the ${toString cfg.maxAgeDays}d threshold" >&2
      exit 1
    fi
  '';
in
{
  options.my.backup = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User whose home directory will be backed up.";
    };

    extraExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional `--exclude=…` arguments appended to the backup.";
    };

    prune = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether this host applies the retention policy. Pruning takes an exclusive
        repository lock, so exactly one host in the fleet should do it.
      '';
    };

    maxAgeDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Alert when this host's newest snapshot is older than this.";
    };

    alertTo = lib.mkOption {
      type = lib.types.str;
      default = "otavio.salvador@gmail.com";
      description = "Address that backup failure and staleness alerts are sent to.";
    };
  };

  config = {
    sops.secrets = {
      "backup/credentials" = { };
      "backup/repository" = { };
      "backup/password" = { };
    };

    services.restic.backups.r2 = {
      user = "root";
      initialize = false;
      createWrapper = true;

      environmentFile = config.sops.secrets."backup/credentials".path;
      repositoryFile = config.sops.secrets."backup/repository".path;
      passwordFile = config.sops.secrets."backup/password".path;

      paths = [ config.users.users.${cfg.user}.home ];

      # A run interrupted mid-prune leaves an exclusive lock that later runs
      # cannot get past. The module only unlocks as part of pruning, which is
      # a single host's job, so every other host needs this.
      backupPrepareCommand = "${resticBin} unlock || true";

      pruneOpts = lib.optionals cfg.prune [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 6"
        "--keep-yearly 0"
      ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };

      extraBackupArgs = [
        "--exclude-caches"
        "--exclude-if-present .backup-ignore"
        "--retry-lock"
        "15m"
      ] ++ cfg.extraExcludes;
    };

    systemd.services."backup-alert@" = {
      description = "Report a failed backup unit by mail";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${alert} %i";
      };
    };

    systemd.services.restic-backups-r2.onFailure = [ "backup-alert@restic-backups-r2.service" ];

    # Failure alerts only fire when a run happens at all; this catches the
    # quieter case where the timer stops firing and nothing is said.
    systemd.services.restic-freshness-r2 = {
      description = "Check that this host has a recent restic snapshot";
      onFailure = [ "backup-alert@restic-freshness-r2.service" ];

      environment = {
        RESTIC_REPOSITORY_FILE = config.sops.secrets."backup/repository".path;
        RESTIC_PASSWORD_FILE = config.sops.secrets."backup/password".path;
      };

      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets."backup/credentials".path;
        ExecStart = freshness.outPath;
      };
    };

    systemd.timers.restic-freshness-r2 = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
