{ inputs, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  claudeWrapped = pkgs.writeShellScriptBin "claude" ''
    # Workaround for https://github.com/anthropics/claude-code/issues/25418
    # Agent teams install an unpatched Linux binary to ~/.local/share/claude
    # that is incompatible with NixOS. Clean up the installation directory
    # so it doesn't get used as an update source.
    rm -rf "$HOME/.local/share/claude"

    exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
  '';
in
{
  home.packages = with pkgs; [ jq ];

  # Place the wrapper at ~/.local/bin/claude so it takes precedence over
  # the Nix profile entry, preventing agent-teams-installed binaries from
  # shadowing the Nix-managed wrapper.
  home.file.".local/bin/claude".source = "${claudeWrapped}/bin/claude";

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = claudeWrapped;
    settings = {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      model = "opus";
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
