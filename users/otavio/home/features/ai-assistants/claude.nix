{ config, inputs, lib, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  # The store path home-manager would otherwise have symlinked into place.
  settingsSource = config.home.file.${settingsPath}.source;
  # Records which store path was last deployed, as a symlink so the activation
  # script can compare with readlink and never needs a shell redirection.
  deployedMarker = "${config.xdg.stateHome}/nix-config/claude-settings";

  statuslineScript = pkgs.writeShellApplication {
    name = "statusline-command";
    runtimeInputs = [ pkgs.jq pkgs.git pkgs.coreutils ];
    text = builtins.readFile ./statusline-command.sh;
  };

  notifySoundCommand = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
  notifySoundHook = { hooks = [{ type = "command"; command = notifySoundCommand; }]; };

  herdrHooks = import ./herdr-hooks.nix { inherit pkgs inputs; };

  credentialGuard = import ./credential-guard.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [ sox ];

  # Claude Code rewrites settings.json in place -- /config, permission grants,
  # plugin toggles -- which a read-only store symlink forbids. Deploy a real
  # copy instead, and replace it only when the Nix-side content actually
  # changes, so edits made inside the harness survive unrelated activations.
  home.file.${settingsPath}.enable = false;

  home.activation.claudeCodeSettings =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ ! -f ${lib.escapeShellArg settingsPath} ] \
        || [ -L ${lib.escapeShellArg settingsPath} ] \
        || [ "$(readlink ${lib.escapeShellArg deployedMarker} 2>/dev/null)" \
             != ${lib.escapeShellArg settingsSource} ]; then
        run rm -f ${lib.escapeShellArg settingsPath}
        run install -Dm600 ${lib.escapeShellArg settingsSource} \
          ${lib.escapeShellArg settingsPath}
      fi
      run mkdir -p ${lib.escapeShellArg (builtins.dirOf deployedMarker)}
      run ln -sfn ${lib.escapeShellArg settingsSource} \
        ${lib.escapeShellArg deployedMarker}
    '';

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    settings = {
      env = {
        CLAUDE_CODE_NO_FLICKER = "1";
      } // credentialGuard.mkAgentEnv "claude";
      model = "opus";
      voiceEnabled = true;
      skipDangerousModePermissionPrompt = true;
      alwaysThinkingEnabled = true;
      awaySummaryEnabled = false;
      outputStyle = "ASD-STE100";

      # Trim unused tool schemas from every request; they ship each turn
      # whether or not the tools are used.
      disableClaudeAiConnectors = true; # Gmail/Calendar/Drive MCP tools

      permissions = {
        defaultMode = "bypassPermissions";
        disableAutoMode = "disable";
        allow = [
          "Bash(find:*)"
          "Bash(ls:*)"
          "Bash(tree:*)"
          "Bash(cat:*)"
          "Bash(git config:*)"
          "Bash(git commit:*)"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:mynixos.com)"
          "WebSearch"

          # .envrc is direnv config, not a secret — allow it explicitly
          # so the broader .env* deny below doesn't block it.
          "Read(**/.envrc)"
          "Edit(**/.envrc)"

          # .env.example is a non-secret template — allow it explicitly
          # so the broader .env* deny below doesn't block it.
          "Read(**/.env.example)"
          "Edit(**/.env.example)"
        ];
        deny = [
          # Drop these unused tool schemas from every request; bare names
          # remove the definition, not just block the call.
          "DesignSync"
          "NotebookEdit"

          # .env files
          "Read(.env*)"
          "Edit(.env*)"
          "Bash(cat *.env*)"
          "Bash(head *.env*)"
          "Bash(tail *.env*)"
          "Bash(less *.env*)"
          "Bash(more *.env*)"

          # secrets/ directory (sops-nix)
          "Read(secrets/**)"
          "Edit(secrets/**)"
          "Read(**/secrets/**)"
          "Edit(**/secrets/**)"
          "Bash(cat *secrets/*)"
          "Bash(head *secrets/*)"
          "Bash(tail *secrets/*)"
          "Bash(less *secrets/*)"
          "Bash(more *secrets/*)"

          # common secret / private-key files
          "Read(**/*.pem)"
          "Read(**/*.key)"
          "Read(**/id_rsa)"
          "Read(**/id_ed25519)"
          "Edit(**/*.pem)"
          "Edit(**/*.key)"
          "Edit(**/id_rsa)"
          "Edit(**/id_ed25519)"
        ];
      };
      statusLine = {
        type = "command";
        command = "${pkgs.lib.getExe statuslineScript}";
      };
      attribution = {
        commit = "";
        pr = "";
      };
      hooks = {
        Notification = [ (notifySoundHook // { matcher = ""; }) ];
        SessionStart = [
          {
            matcher = "*";
            hooks = [{
              type = "command";
              command = "bash ${herdrHooks}/claude-hook.sh session";
              timeout = 10;
            }];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "rtk hook claude";
              }
            ];
          }
        ];
      };

      # Plugin marketplace configuration
      extraKnownMarketplaces = {
        ossystems-ai-plugins = {
          source = {
            source = "github";
            repo = "OSSystems/ai-plugins";
          };
          autoUpdate = true;
        };
        ui-ux-pro-max-skill = {
          source = {
            source = "github";
            repo = "nextlevelbuilder/ui-ux-pro-max-skill";
          };
          autoUpdate = true;
        };
        knowledge-work-plugins = {
          source = {
            source = "github";
            repo = "anthropics/knowledge-work-plugins";
          };
          autoUpdate = true;
        };
        custom-claude-code-plugins = {
          source = {
            source = "github";
            repo = "stefanoginella/claude-code-plugins";
          };
          autoUpdate = true;
        };
        claude-plugins-official = {
          source = {
            source = "github";
            repo = "anthropics/claude-plugins-official";
          };
          autoUpdate = true;
        };
        freedom-rtos-ai = {
          source = {
            source = "github";
            repo = "FreedomVeiculosEletricos/freedom-rtos-ai";
          };
          autoUpdate = true;
        };
        anthropic-agent-skills = {
          source = {
            source = "github";
            repo = "anthropics/skills";
          };
          autoUpdate = true;
        };
      };

      # Enable plugins from the marketplace
      enabledPlugins = {
        "ossystems-commit@ossystems-ai-plugins" = true;
        "ossystems-herdr@ossystems-ai-plugins" = true;
        "ossystems-refactor-agent-instructions@ossystems-ai-plugins" = true;
        # auto-bmad@custom-claude-code-plugins is installed per-project
      };
    };

    outputStyles."ASD-STE100" = ''
      ---
      name: ASD-STE100
      description: Simplified Technical English — one meaning per word, active voice, simple tenses, short sentences
      keep-coding-instructions: true
      ---

      Write all responses in Simplified Technical English, as specified by
      ASD-STE100. The goal is text that a reader with limited English can
      understand correctly on the first reading.

      ## Words

      - Give each word one meaning only. Use the same word for the same idea
        every time. Do not use synonyms for variety.
      - Prefer short, common words. Write "use", not "utilize". Write "start",
        not "initiate". Write "before", not "prior to".
      - Keep technical names, command names, file paths, option names, and code
        exactly as they are. Never simplify an identifier.
      - Do not use idioms, metaphors, slang, or humor.
      - Do not put more than three nouns together. Break long noun clusters into
        a phrase with a preposition.

      ## Sentences

      - Use the active voice. Name the actor: "The timer starts the service",
        not "The service is started".
      - Keep instructions to 20 words or less. Keep descriptive sentences to 25
        words or less.
      - Write one instruction in one sentence. Put each action in its own step.
      - Start an instruction with the verb: "Run the command", "Open the file".
      - Keep articles ("a", "the") in place. Do not write telegraphic text.
      - Use simple tenses. Avoid the perfect and progressive forms when a simple
        tense says the same thing.
      - Do not use a gerund or a participle as a noun or an adjective when a
        simple verb or a relative clause is possible.
      - Write positively. Do not use two negatives in one sentence.

      ## Text structure

      - Keep a paragraph to six sentences or less.
      - Put the most important statement first. State the result, then the
        detail.
      - Use a numbered list for a sequence of actions. Use a bulleted list for
        items with no order.
      - Use a table when you compare three or more things.
      - Write a warning or a caution before the step it applies to, never after.

      ## Engineering accuracy comes first

      Simplified English must not remove necessary information. If a fact is
      complex, divide it into more sentences. Do not delete it, and do not make
      it vague. State uncertainty in plain words: "This is not verified."
    '';
  };
}
