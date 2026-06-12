{ inputs, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  statuslineScript = pkgs.writeShellApplication {
    name = "statusline-command";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./statusline-command.sh;
  };

  notifySoundCommand = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
  notifySoundHook = { hooks = [{ type = "command"; command = notifySoundCommand; }]; };

  herdrHooks = import ./herdr-hooks.nix { inherit pkgs inputs; };

  credentialGuard = import ./credential-guard.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [ sox ];

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    settings = {
      env = {
        CLAUDE_CODE_EFFORT_LEVEL = "high";
        CLAUDE_CODE_NO_FLICKER = "1";
      } // credentialGuard.mkAgentEnv "claude";
      model = "opus";
      voiceEnabled = true;
      skipDangerousModePermissionPrompt = true;
      alwaysThinkingEnabled = true;
      awaySummaryEnabled = false;
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
          "Write(**/.envrc)"

          # .env.example is a non-secret template — allow it explicitly
          # so the broader .env* deny below doesn't block it.
          "Read(**/.env.example)"
          "Edit(**/.env.example)"
          "Write(**/.env.example)"
        ];
        deny = [
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
        };
        ui-ux-pro-max-skill = {
          source = {
            source = "github";
            repo = "nextlevelbuilder/ui-ux-pro-max-skill";
          };
        };
        knowledge-work-plugins = {
          source = {
            source = "github";
            repo = "anthropics/knowledge-work-plugins";
          };
        };
        custom-claude-code-plugins = {
          source = {
            source = "github";
            repo = "stefanoginella/claude-code-plugins";
          };
        };
        claude-plugins-official = {
          source = {
            source = "github";
            repo = "anthropics/claude-plugins-official";
          };
        };
        freedom-rtos-ai = {
          source = {
            source = "github";
            repo = "FreedomVeiculosEletricos/freedom-rtos-ai";
          };
        };
        anthropic-agent-skills = {
          source = {
            source = "github";
            repo = "anthropics/skills";
          };
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
  };
}
