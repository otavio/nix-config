{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.diskCleanup;

  steps = [
    "direnv"
    "results"
    "yocto"
    "docker"
    "caches"
    "nix-gc"
    "balance"
  ];

  disk-cleanup = pkgs.writeShellApplication {
    name = "disk-cleanup";
    runtimeInputs = with pkgs; [
      btrfs-progs
      config.nix.package
      coreutils
      docker-client
      findutils
      gawk
      gnused
      procps
      util-linux
    ];
    text = ''
      DC_USER=${lib.escapeShellArg cfg.user}
      DC_HOME=${lib.escapeShellArg config.users.users.${cfg.user}.home}
      DC_AGE_DAYS=${toString cfg.ageDays}
      DC_DIRENV_PATHS=${lib.escapeShellArg (toString cfg.direnvPaths)}
      DC_YOCTO_PATHS=${lib.escapeShellArg (toString cfg.yoctoPaths)}
      DC_CACHE_EXCLUDES=${lib.escapeShellArg (toString cfg.cacheExcludes)}
      DC_STEPS=${lib.escapeShellArg (lib.concatStringsSep "," steps)}

      ${builtins.readFile ./disk-cleanup.sh}
    '';
  };
in
{
  options.my.diskCleanup = {
    enable = lib.mkEnableOption "the disk-cleanup command";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User whose home, caches and rootless docker are cleaned.";
    };

    ageDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = "Anything idle for longer than this many days is removed.";
    };

    direnvPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "src"
        ".t3/worktrees"
      ];
      description = "Directories, relative to the user's home, searched for stale .direnv roots.";
    };

    yoctoPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories, relative to the user's home, searched for idle Yocto builds.";
    };

    cacheExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Entries of ~/.cache never pruned.";
    };

    automatic = {
      enable = lib.mkEnableOption "running disk-cleanup --apply on a timer";

      dates = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "systemd OnCalendar expression for the automatic run.";
      };

      skip = lib.mkOption {
        type = lib.types.listOf (lib.types.enum steps);
        default = [ ];
        description = "Steps left out of the automatic run.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ disk-cleanup ];

    systemd = lib.mkIf cfg.automatic.enable {
      services.disk-cleanup = {
        description = "Reclaim disk space";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.escapeShellArgs (
            [
              (lib.getExe disk-cleanup)
              "--apply"
            ]
            ++ lib.optionals (cfg.automatic.skip != [ ]) [
              "--skip"
              (lib.concatStringsSep "," cfg.automatic.skip)
            ]
          );
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
      timers.disk-cleanup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.automatic.dates;
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
