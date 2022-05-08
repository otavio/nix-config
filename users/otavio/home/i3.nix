{ config
, lib
, pkgs
, hostname
, ...
}:
let
  modifier = "Mod4";

  editor = "emacsclient -c -a 'emacs'";
  terminal = "i3-sensible-terminal --class=term";
  menu = "i3-sensible-terminal -t 'fzf-menu' --class 'fzf-menu' -e fzf-menu";

  dunstCloseNotification = "dunstctl close";

  shellWs = "1: shell ";
  editorWs = "2: editor ";
  browserWs = "3: browser ";
  triviaWs = "10: trivia ";
in
{
  # Ref: https://discourse.nixos.org/t/opening-i3-from-home-manager-automatically/4849/8
  xsession.scriptPath = ".hm-xsession";

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      inherit modifier terminal menu;

      assigns = {
        "${shellWs}" = [{ class = "Alacritty"; instance = "term"; }];
        "${editorWs}" = [{ class = "Emacs"; }];
        "${browserWs}" = [
          { class = "Google-chrome"; }
          { class = "Firefox"; }
          { class = "Brave"; }
          { class = "chromium"; }
        ];

        "${triviaWs}" = [
          { class = "skype"; }
          { class = "slack"; }
          { class = "discord"; }
          { class = "telegram-desktop"; }
        ];
      };

      bars = [
        {
          position = "bottom";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${./i3/i3status-rust.toml}";
          fonts = {
            names = [ "FontAwesome" "Iosevka" ];
            size = 9.0;
          };
          colors = {
            background = "#000000";
            statusline = "#ffffff";
            separator = "#666666";
            focusedWorkspace = {
              border = "#4c7899";
              background = "#285577";
              text = "#ffffff";
            };
            activeWorkspace = {
              border = "#333333";
              background = "#5f676a";
              text = "#ffffff";
            };
            inactiveWorkspace = {
              border = "#333333";
              background = "#222222";
              text = "#888888";
            };
            urgentWorkspace = {
              border = "#2f343a";
              background = "#900000";
              text = "#ffffff";
            };
            bindingMode = {
              border = "#2f343a";
              background = "#900000";
              text = "#ffffff";
            };
          };
        }
      ];

      fonts = {
        names = [ "DejaVuSansMono" "Terminus" ];
        style = "Bold Semi-Condensed";
        size = 9.0;
      };

      focus.followMouse = false;

      keybindings = lib.mkOptionDefault {
        "${modifier}+x" = "kill";

        "${modifier}+l" = "focus left";
        "${modifier}+k" = "focus down";
        "${modifier}+j" = "focus up";
        "${modifier}+semicolon" = "focus right";

        "${modifier}+Shift+l" = "move left";
        "${modifier}+Shift+k" = "move down";
        "${modifier}+Shift+j" = "move up";
        "${modifier}+Shift+semicolon" = "move right";

        "${modifier}+1" = "workspace number ${shellWs}";
        "${modifier}+2" = "workspace number ${editorWs}";
        "${modifier}+3" = "workspace number ${browserWs}";
        "${modifier}+0" = "workspace number ${triviaWs}";

        "${modifier}+Shift+1" = "move container to workspace number ${shellWs}";
        "${modifier}+Shift+2" = "move container to workspace number ${editorWs}";
        "${modifier}+Shift+3" = "move container to workspace number ${browserWs}";
        "${modifier}+Shift+0" = "move container to workspace number ${triviaWs}";

        "Print" = "exec flameshot gui";

        # Hide dunst notification.
        "Control+Shift+space" = "exec ${dunstCloseNotification}";
      };

      window.commands = [
        {
          criteria = { workspace = "${triviaWs}"; };
          command = "layout tabbed";
        }

        {
          criteria = { class = "floating"; };
          command = "floating enable";
        }

        {
          criteria = { title = "fzf-menu"; };
          command = "border none sticky enable floating enable focus";
        }
      ];

      startup = [
        { command = "pa-applet"; notification = true; }
        { command = "Discord"; notification = true; }
        { command = "telegram-desktop"; notification = true; }
      ] ++ pkgs.lib.lists.optionals (hostname == "micro") [
        { command = editor; notification = true; }
        { command = terminal; notification = true; }
        { command = "brave"; notification = true; }
        { command = "skypeforlinux"; notification = true; }
        { command = "slack"; notification = true; }
      ];
    };
  };

  home.packages = with pkgs; [ fzf i3 pa_applet ];

  home.file.".xinitrc".source = ./i3/xinitrc;
}
