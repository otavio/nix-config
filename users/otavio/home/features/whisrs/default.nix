{ inputs, pkgs, ... }:

let
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
in
{
  imports = [ ./module.nix ../snixembed ];

  services.whisrs = {
    enable = true;
    package = inputs.whisrs.packages.${pkgs.stdenv.hostPlatform.system}.default;
    openai.apiKeyFile = "/run/secrets/openai_api_key";

    xkb = {
      layout = "us";
      variant = "intl";
    };

    settings = {
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
      # Pinned to whisrs's own default so an upstream change to it can't
      # silently slow typing back down.
      input.key_delay_ms = 2;
      # Dated snapshot rather than the floating alias: it is tuned for short
      # utterances and background noise, which is where en/pt drift under
      # language="auto" showed up. Same price as the alias.
      openai.model = "gpt-4o-mini-transcribe-2025-12-15";
    };
  };
}
