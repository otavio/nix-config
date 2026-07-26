{ inputs, lib, pkgs, ... }:

let
  whisrs = inputs.whisrs.packages.${pkgs.stdenv.hostPlatform.system}.default;

  basePrompt = ''
    Otavio Salvador speaking. Professional, technical register: software
    engineering, embedded Linux, the Yocto Project, AI agent workflows.
    Speech is in English or Brazilian Portuguese; transcribe in the
    spoken language. When speaking Portuguese, keep borrowed English
    technical terms in English (commit, deploy, build, merge, branch,
    push, log, prompt, agent). Preserve technical tokens verbatim:
    file paths, CLI flags like --foo, file extensions, camelCase and
    snake_case identifiers. Keep proper nouns in canonical casing
    (NixOS, GitHub, Yocto, Yocto Project, Claude, Codex); when "Yocto"
    is followed by "Project", always capitalize Project. Render spoken
    punctuation cues ("comma"/"vírgula", "period"/"ponto", "new
    line"/"nova linha") as the punctuation itself, not as the word.
    Transcribe verbatim. Fix obvious punctuation (commas, periods,
    question marks); do not rephrase, reformat, summarize, or correct
    word choice. Apply other edits only when the speaker explicitly
    asks for them in the audio (e.g. "make this a bullet list",
    "rewrite this sentence as ...").
  '';

  vocabulary = [
    # nix / personal stack
    "Nix"
    "NixOS"
    "nixpkgs"
    "Home Manager"
    "Colmena"
    "flake"
    "SOPS"
    "sops-nix"
    "whisrs"
    "Talon"
    "snixembed"
    "i3wm"
    "Emacs"
    # AI / agent workflows
    "OpenAI"
    "Anthropic"
    "Claude"
    "Codex"
    "sub-agent"
    "tool call"
    "MCP"
    "slash command"
    "prompt cache"
    "context window"
    # git / PR workflow
    "rebase"
    "cherry-pick"
    "fixup"
    "force-push"
    "fast-forward"
    "hunk"
    "upstream"
    "fork"
    # embedded Linux / Yocto
    "Yocto"
    "Yocto Project"
    "BitBake"
    "Buildroot"
    "U-Boot"
    "OpenEmbedded"
    "device tree"
    "rootfs"
    "initramfs"
    "BSP"
    "SPL"
    "TF-A"
    "bbappend"
    # people / places
    "O.S. Systems"
    "Otavio"
    "Otávio"
    "Salvador"
    "Bruna"
    "São Paulo"
    "Rio Grande do Sul"
  ];

  configFile = (pkgs.formats.toml { }).generate "whisrs-config.toml" {
    general = {
      backend = "openai";
      language = "auto";
      silence_timeout_ms = 2000;
      notify = true;
      remove_filler_words = true;
      audio_feedback = true;
      audio_feedback_volume = 0.2;
      inherit vocabulary;
      prompt = basePrompt;
    };
    # Pinned to whisrs's own default so an upstream change to it can't silently
    # slow typing back down.
    input.key_delay_ms = 2;
    openai = {
      # Required by the deserializer; left empty so whisrs falls back to
      # WHISRS_OPENAI_API_KEY (injected by the systemd wrapper below).
      api_key = "";
      # Dated snapshot rather than the floating alias: it is tuned for short
      # utterances and background noise, which is where en/pt drift under
      # language="auto" showed up. Same price as the alias.
      model = "gpt-4o-mini-transcribe-2025-12-15";
    };
  };

  whisrsd-start = pkgs.writeShellApplication {
    name = "whisrsd-start";
    text = ''
      WHISRS_OPENAI_API_KEY="$(< /run/secrets/openai_api_key)"
      export WHISRS_OPENAI_API_KEY
      exec ${lib.getExe' whisrs "whisrsd"}
    '';
  };
in
{
  imports = [ ../snixembed ];

  xdg.configFile."whisrs/config.toml".source = configFile;

  home.packages = [ whisrs ];

  services.snixembed.beforeUnits = [ "whisrs.service" ];

  systemd.user.services.whisrs = {
    Unit = {
      Description = "whisrs speech-to-text daemon";
      # Hard-require snixembed: whisrs's tray code retries
      # RegisterStatusNotifierItem 10x with backoff and then permanently
      # disables the tray for the rest of the process lifetime. If snixembed
      # isn't already up when whisrs starts, the icon stays missing until the
      # next restart. `services.snixembed.beforeUnits` only adds ordering, so
      # pin the dependency here too so whisrs is held back until snixembed has
      # claimed `org.kde.StatusNotifierWatcher`.
      Requires = [ "snixembed.service" ];
      After = [ "graphical-session-pre.target" "snixembed.service" ];
      PartOf = [ "graphical-session.target" ];
      # whisrs reads config.toml only at startup, and sd-switch restarts a unit
      # only when the unit file changes. Without the config's store path here,
      # editing it leaves the unit identical and the daemon keeps the old
      # settings until the next manual restart.
      X-Restart-Triggers = [ "${configFile}" ];
    };
    Service = {
      ExecStart = lib.getExe whisrsd-start;
      Restart = "on-failure";
      # whisrs auto-detects only Hyprland/Sway; under X11/i3 it falls back to
      # xkbcommon's default (us, no variant). Mirror the active X11 layout so
      # dead keys (', ", `, ^, ~ on us:intl) get routed through clipboard
      # paste instead of arriving as combining accents on the next character.
      Environment = [
        "XKB_DEFAULT_LAYOUT=us"
        "XKB_DEFAULT_VARIANT=intl"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
