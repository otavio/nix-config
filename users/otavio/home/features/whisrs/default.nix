{ inputs, lib, pkgs, ... }:

let
  whisrs = inputs.whisrs.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    preCheck = (old.preCheck or "") + ''
      export HOME=$(mktemp -d)
    '';
  });

  # Combined prompt+vocabulary must stay under whisper's 244-token cap;
  # excess gets silently truncated from the front, eating the framing.
  basePrompt = ''
    Otavio Salvador speaking. Professional, technical register: software
    engineering, embedded Linux, the Yocto Project, AI agent workflows.
    Speech is in English or Brazilian Portuguese; transcribe in the
    spoken language. When speaking Portuguese, keep borrowed English
    technical terms in English (commit, deploy, build, merge, branch,
    push, log, prompt, agent). Preserve technical tokens verbatim:
    file paths, CLI flags like --foo, file extensions, camelCase and
    snake_case identifiers. Keep proper nouns in canonical casing
    (NixOS, GitHub, Yocto, Claude, Codex). Render spoken punctuation
    cues ("comma"/"vírgula", "period"/"ponto", "new line"/"nova linha")
    as the punctuation itself, not as the word.
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
    input = {
      # Raised from the 2ms default to balance accuracy in Node/Ink TUIs
      # (e.g. Claude Code) without making typing feel sluggish (whisrs
      # PR #14, issue #12).
      key_delay_ms = 30;
    };
    openai = {
      # Required by the deserializer; left empty so whisrs falls back to
      # WHISRS_OPENAI_API_KEY (injected by the systemd wrapper below).
      api_key = "";
      # gpt-4o-mini-transcribe is more accurate than whisper-1 but follows
      # the `prompt` field as a language hint less reliably, so short
      # utterances can drift off en/pt under language="auto".
      model = "gpt-4o-mini-transcribe";
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
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
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
