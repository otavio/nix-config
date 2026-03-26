{ inputs, pkgs, ... }:
let
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  statuslineScript = pkgs.writeShellScript "statusline-command.sh" ''
    # Read JSON input from stdin
    input=$(cat)

    # Extract values from JSON
    project_dir=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.project_dir')
    dir_name=$(basename "$project_dir")
    model_name=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name')
    remaining_pct=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.context_window.remaining_percentage // empty')

    # Calculate used percentage with normalized context (accounting for ~16.5% autocompact buffer)
    if [ -n "$remaining_pct" ]; then
      # remaining_pct is 0-100, scale to 0-1000 for integer math
      remaining_scaled=$((remaining_pct * 10))
      # Normalize: subtract 165 (16.5%) buffer, scale to usable range
      usable_remaining=$(( (remaining_scaled - 165) * 1000 / (1000 - 165) ))
      # Clamp to 0-1000
      [ "$usable_remaining" -lt 0 ] 2>/dev/null && usable_remaining=0
      [ "$usable_remaining" -gt 1000 ] 2>/dev/null && usable_remaining=1000
      used_scaled=$((1000 - usable_remaining))
      used_pct=$((used_scaled / 10))
    else
      # Fallback to token-based calculation
      context_size=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.context_window.context_window_size')
      current_usage=$(echo "$input" | ${pkgs.jq}/bin/jq '.context_window.current_usage')
      if [ "$current_usage" != "null" ]; then
        input_tokens=$(echo "$current_usage" | ${pkgs.jq}/bin/jq '.input_tokens')
        cache_creation=$(echo "$current_usage" | ${pkgs.jq}/bin/jq '.cache_creation_input_tokens')
        cache_read=$(echo "$current_usage" | ${pkgs.jq}/bin/jq '.cache_read_input_tokens')
        current_tokens=$((input_tokens + cache_creation + cache_read))
        used_pct=$((current_tokens * 100 / context_size))
      else
        used_pct=0
      fi
    fi

    # Clamp used_pct to 0-100
    [ "$used_pct" -lt 0 ] 2>/dev/null && used_pct=0
    [ "$used_pct" -gt 100 ] 2>/dev/null && used_pct=100

    # Build 10-segment progress bar
    filled=$((used_pct / 10))
    empty=$((10 - filled))
    bar=""
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done

    # Dynamic color based on usage thresholds
    if [ "$used_pct" -lt 50 ]; then
      color="\033[32m"  # green
    elif [ "$used_pct" -lt 65 ]; then
      color="\033[33m"  # yellow
    elif [ "$used_pct" -lt 80 ]; then
      color="\033[38;5;208m"  # orange
    else
      color="\033[5;31m"  # blinking red
      bar="💀 ''${bar}"
    fi
    reset="\033[0m"

    # Output: directory | model | ████░░░░░░ 40%
    printf "\033[36m%s''${reset} | \033[35m%s''${reset} | ''${color}%s %d%%''${reset}" \
      "$dir_name" \
      "$model_name" \
      "$bar" \
      "$used_pct"
  '';

in
{
  home.packages = with pkgs; [ jq sox ];

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code-fhs;
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
        command = "${statuslineScript}";
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
