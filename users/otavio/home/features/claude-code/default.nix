{ inputs, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
in
{
  home.packages = with pkgs; [ jq ];

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    settings = {
      model = "opus";
      alwaysThinkingEnabled = true;
      permissions = {
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
        command = "bash ~/.claude/statusline-command.sh";
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
      };

      # Enable plugins from the marketplace
      enabledPlugins = {
        "ossystems-commit@ossystems" = true;
        "ossystems-refactor-claude-md@ossystems" = true;
        "ui-ux-pro-max@ui-ux-pro-max-skill" = true;
        "legal@knowledge-work-plugins" = true;
      };
    };
  };
}
