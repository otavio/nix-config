{ config
, lib
, pkgs
, hostname
, ...
}:
let
  modifier = "Mod4";

  editor = "emacs -nw";
  terminal = "i3-sensible-terminal --class=term";
  menu = "i3-sensible-terminal -t 'fzf-menu' --class 'fzf-menu' -e ${fzf-menu}/bin/i3-fzf-menu";

  dunstCloseNotification = "dunstctl close";

  shellWs = "1: shell ";
  editorWs = "2: editor ";
  browserWs = "3: browser ";
  triviaWs = "10: trivia ";

  fzf-menu = pkgs.writeScriptBin "i3-fzf-menu" (builtins.readFile (pkgs.substituteAll {
    src = ./fzf-menu;
    fzf = "${pkgs.fzf}/bin/fzf";
  }));
in
{
  # Ref: https://discourse.nixos.org/t/opening-i3-from-home-manager-automatically/4849/8
  xsession.scriptPath = ".hm-xsession";

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      inherit modifier terminal menu;

      assigns = {
        "${shellWs}" = [{ class = "term"; instance = "term"; }];
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
          statusCommand = "${config.programs.i3status-rust.package}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml";
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
      ] ++ pkgs.lib.lists.optionals (hostname == "micro") [
        { command = "Discord"; notification = true; }
        { command = editor; notification = true; }
        { command = terminal; notification = true; }
        { command = "brave"; notification = true; }
        { command = "skypeforlinux"; notification = true; }
        { command = "slack"; notification = true; }
        { command = "telegram-desktop"; notification = true; }
      ];
    };
  };

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  programs.i3status-rust = {
    enable = true;

    bars = {
      bottom = {
        theme = "modern";
        icons = "awesome5";
        blocks = [
          {
            block = "weather";
            format = " $icon $weather ($location) $temp, $wind m/s $direction ";
            service = {
              name = "openweathermap";
              api_key = "0f9d6aa5c9af7b7249a0320d1032ddd2";
              city_id = "3454244";
              units = "metric";
            };
          }
          {
            block = "net";
            format = " $icon {$signal_strength $ssid $frequency|Wired connection} IP: $ip {/ $ipv6|} ";
            click = [{ button = "left"; cmd = "alacritty -e nmtui"; }];
          }
          {
            block = "net";
            format = " $icon WireGuard VPN ";
            missing_format = "";
            device = "wg0";
          }
          {
            block = "bluetooth";
            mac = "9C:28:B3:A3:75:0A";
            disconnected_format = " $icon $name ";
            format = " $icon $name{ $percentage|} ";
          }
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            alert_unit = "GB";
            interval = 20;
            warning = 20.0;
            alert = 10.0;
            format = " $icon root: $available.eng(w:2) ";
          }
          {
            block = "memory";
            format = " $icon $mem_total_used_percents.eng(w:2) ";
            format_alt = " $icon_swap $swap_used_percents.eng(w:2) ";
          }

          {
            block = "cpu";
          }
          {
            block = "load";
            interval = 1;
            format = " $icon 1min avg: $1m.eng(w:4) ";
          }
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%a %d/%m %R') ";
          }
          {
            block = "battery";
            interval = 10;
            device = "/sys/class/power_supply/max170xx_battery";
            format = " $icon $percentage ";
            missing_format = "";
          }
        ];
      };
    };
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    font-awesome
    source-code-pro
    jetbrains-mono
    iosevka-bin
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })

    fzf
    i3
    pa-applet
    pavucontrol
    xclip
    xss-lock
  ];

  home.file.".xinitrc".source = ./xinitrc;
}
