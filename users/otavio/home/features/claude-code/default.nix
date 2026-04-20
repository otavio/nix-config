{ inputs, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  claude-code-fhs = pkgs.buildFHSEnv {
    name = "claude";
    inherit (pkgs.claude-code) meta;
    targetPkgs = _: with pkgs; [ claude-code stdenv.cc.cc.lib zlib ];
    runScript = pkgs.lib.getExe pkgs.claude-code;
  };

  statuslineScript = pkgs.writeShellApplication {
    name = "statusline-command";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./statusline-command.sh;
  };

in
{
  home.packages = with pkgs; [ jq sox ];

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = claude-code-fhs;
    settings = {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      model = "opus";
      voiceEnabled = true;
      skipDangerousModePermissionPrompt = true;
      alwaysThinkingEnabled = true;
      permissions = {
        defaultMode = "bypassPermissions";
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
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
              }
            ];
          }
        ];
      };

      # Plugin marketplace configuration
      extraKnownMarketplaces = {
        ossystems = {
          source = {
            source = "github";
            repo = "OSSystems/claude-code-plugin";
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
      };

      # Enable plugins from the marketplace
      enabledPlugins = {
        "ossystems-commit@ossystems" = true;
        "ossystems-refactor-claude-md@ossystems" = true;
        "ui-ux-pro-max@ui-ux-pro-max-skill" = true;
        "legal@knowledge-work-plugins" = true;
        # auto-bmad@custom-claude-code-plugins is installed per-project
      };
    };
  };
}
