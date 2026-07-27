{ config, lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.services.whisrs;

  apiKeyEnvVar = provider: "WHISRS_${lib.toUpper provider}_API_KEY";

  mkApiKeyFileOption = provider: lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    example = "/run/secrets/whisrs-${provider}-api-key";
    description = ''
      File holding the ${provider} API key, read at service start and
      exported as `${apiKeyEnvVar provider}`. Use this instead of an
      `api_key` in {option}`services.whisrs.settings`, which would put
      the key in the world-readable Nix store. The file must be readable
      by the user running the service.
    '';
  };

  exportApiKey = provider: file: ''
    ${apiKeyEnvVar provider}="$(< ${lib.escapeShellArg file})"
    export ${apiKeyEnvVar provider}
  '';

  # whisrs reads a key from the environment for these providers only.
  apiKeyFiles = {
    openai = cfg.openai.apiKeyFile;
    groq = cfg.groq.apiKeyFile;
    deepgram = cfg.deepgram.apiKeyFile;
  };

  activeApiKeyFiles = lib.filterAttrs (_: file: file != null) apiKeyFiles;

  # whisrs declares `api_key` on each provider table without a serde
  # default, so any table reaching config.toml must carry the field even
  # when the real key arrives through the environment.
  apiKeyPlaceholders = lib.genAttrs
    (lib.filter
      (provider: activeApiKeyFiles ? ${provider} || cfg.settings ? ${provider})
      (lib.attrNames apiKeyFiles))
    (_: { api_key = ""; });

  settings = lib.recursiveUpdate apiKeyPlaceholders cfg.settings;

  # whisrs registers a StatusNotifierItem unless general.tray is turned off.
  # Its tray code retries RegisterStatusNotifierItem 10x with backoff and then
  # disables the tray for the rest of the process lifetime, so it has to wait
  # for a provider to own the watcher name rather than merely be spawned.
  # Wants rather than Requires: a tray provider that never claims the name
  # should cost the icon, not dictation.
  usesTray = cfg.settings.general.tray or true;

  configFile = tomlFormat.generate "whisrs-config.toml" settings;

  whisrsdStart = pkgs.writeShellApplication {
    name = "whisrsd-start";
    text =
      lib.concatStrings (lib.mapAttrsToList exportApiKey activeApiKeyFiles)
      + ''
        exec ${lib.getExe' cfg.package "whisrsd"}
      '';
  };
in
{
  meta.maintainers = [ lib.maintainers.otavio ];

  options.services.whisrs = {
    enable = lib.mkEnableOption "whisrs, a speech-to-text dictation daemon" // {
      description = ''
        Whether to enable whisrs, a speech-to-text dictation daemon.

        whisrs types through a uinput virtual keyboard, so the user running
        it needs write access to {file}`/dev/uinput`. Home Manager cannot
        arrange that; on NixOS it takes `hardware.uinput.enable` and
        membership of the `uinput` group. Without it the daemon starts
        cleanly and then types nothing.
      '';
    };

    package = lib.mkPackageOption pkgs "whisrs" { };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/whisrs/config.toml`. See
        <https://github.com/y0sif/whisrs> for the full list of options.

        whisrs reads this only at startup, so the service is restarted
        whenever it changes. Do not set any `api_key` here; use the
        `apiKeyFile` options instead.
      '';
      example = lib.literalExpression ''
        {
          general = {
            backend = "openai";
            language = "auto";
            vocabulary = [ "NixOS" "Yocto Project" ];
          };
          input.key_delay_ms = 2;
          openai.model = "gpt-4o-mini-transcribe";
        }
      '';
    };

    openai.apiKeyFile = mkApiKeyFileOption "openai";
    groq.apiKeyFile = mkApiKeyFileOption "groq";
    deepgram.apiKeyFile = mkApiKeyFileOption "deepgram";

    xkb = {
      layout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "us";
        description = ''
          Keyboard layout the virtual keyboard types with, exported as
          `XKB_DEFAULT_LAYOUT`.

          whisrs probes the compositor, then `setxkbmap`, then `localectl`,
          and consults the environment only if all of those come up empty.
          Set this when none of them reach the right answer — typically a
          `systemd --user` service that cannot see `DISPLAY` — since the
          fallback layout mistypes anything the active layout maps
          differently.
        '';
      };

      variant = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "intl";
        description = ''
          Layout variant, exported as `XKB_DEFAULT_VARIANT` alongside
          {option}`services.whisrs.xkb.layout`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.whisrs" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."whisrs/config.toml" = lib.mkIf (settings != { }) {
      source = configFile;
    };

    systemd.user.services.whisrs = {
      Unit = {
        Description = "whisrs speech-to-text daemon";
        Documentation = "https://github.com/y0sif/whisrs";
        Wants = lib.optional usesTray "tray.target";
        After = [ "graphical-session-pre.target" ]
          ++ lib.optional usesTray "tray.target";
        PartOf = [ "graphical-session.target" ];
        # sd-switch restarts a unit only when the unit file changes.
        # Without the config's store path here, editing it leaves the unit
        # identical and the daemon keeps the old settings until the next
        # manual restart.
        X-Restart-Triggers =
          lib.optional (settings != { }) "${configFile}";
      };
      Service = {
        ExecStart =
          if activeApiKeyFiles != { } then
            lib.getExe whisrsdStart
          else
            lib.getExe' cfg.package "whisrsd";
        Restart = "on-failure";
        Environment =
          lib.optional (cfg.xkb.layout != null)
            "XKB_DEFAULT_LAYOUT=${cfg.xkb.layout}"
          ++ lib.optional (cfg.xkb.variant != null)
            "XKB_DEFAULT_VARIANT=${cfg.xkb.variant}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
