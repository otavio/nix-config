{ config, lib, pkgs, ... }:
let mod = "Mod4";
in {
  xsession.scriptPath =
    ".hm-xsession"; # Ref: https://discourse.nixos.org/t/opening-i3-from-home-manager-automatically/4849/8

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = mod;

      bars = [{
        position = "bottom";
        statusCommand =
          "${pkgs.i3status-rust}/bin/i3status-rs ${./i3/i3status-rust.toml}";
        fonts = {
          names = [ "FontAwesome" "Iosevka" ];
          size = 9.0;
        };
      }];

      fonts = {
        names = [ "DejaVuSansMono" "Terminus" ];
        style = "Bold Semi-Condensed";
        size = 9.0;
      };

      keybindings = lib.mkOptionDefault {
        "${mod}+Return" = "exec i3-sensible-terminal";
        "${mod}+x" = "kill";
        "${mod}+r" = "exec dmenu_run";

        "${mod}+l" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+j" = "focus up";
        "${mod}+semicolon" = "focus right";

        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";

        "${mod}+Shift+l" = "move left";
        "${mod}+Shift+k" = "move down";
        "${mod}+Shift+j" = "move up";
        "${mod}+Shift+semicolon" = "move right";

        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        "${mod}+h" = "split h";
        "${mod}+v" = "split v";
        "${mod}+f" = "fullscreen toggle";

        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";

        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";

        "${mod}+a" = "focus parent";

        "${mod}+Shift+minus" = "move scratchpad";
        "${mod}+minus" = "scratchpad show";

        "${mod}+1" = "workspace number $WS1";
        "${mod}+2" = "workspace number $WS2";
        "${mod}+3" = "workspace number $WS3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number $WS8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        "${mod}+Shift+1" = "move container to workspace number $WS1";
        "${mod}+Shift+2" = "move container to workspace number $WS2";
        "${mod}+Shift+3" = "move container to workspace number $WS3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number $WS8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

        "Print" = "exec flameshot gui";

        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

        "${mod}+Shift+r" = "mode resize";
      };
    };
    extraConfig = ''
      set $WS1 "1: shell "
      set $WS2 "2: editor "
      set $WS3 "3: browser "
      set $WS8 "8: trivia "

      assign [class="Alacritty"] $WS1
      assign [class="Emacs"] $WS2

      assign [class="Google-chrome"] $WS3
      assign [class="Firefox"] $WS3
      assign [class="chromium"] $WS3

      assign [class="skype"] 10
      assign [class="slack"] 10
      assign [class="discord"] 10

      for_window [class="floating"] floating enable;
      for_window [workspace=10] layout tabbed;

      # Start applications
      exec firefox
      exec skypeforlinux
      exec Discord
      exec slack
      exec emacs
      exec i3-sensible-terminal
    '';
  };

  home.packages = with pkgs; [ i3 dmenu ];

  home.file.".xinitrc".source = ../nix/i3/xinitrc;
}
