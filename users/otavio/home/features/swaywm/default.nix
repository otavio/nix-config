{ config
, lib
, pkgs
, hostname
, ...
}:
let
  modifier = "Mod4";

  copyq = "copyq";
  editor = "emacs -nw";
  terminal = "alacritty --class=term";
  menu = "alacritty -t 'fzf-menu' --class 'fzf-menu' -e ${fzf-menu}/bin/i3-fzf-menu";

  dunstCloseNotification = "dunstctl close";

  shellWs = "1: shell ";
  editorWs = "2: editor ";
  browserWs = "3: browser ";
  triviaWs = "10: trivia ";

  fzf-menu = pkgs.writeScriptBin "i3-fzf-menu" (builtins.readFile (pkgs.replaceVars ./fzf-menu {
    fzf = "${pkgs.fzf}/bin/fzf";
  }));
in
{
  wayland.windowManager.sway = {
    enable = true;

    config = {
      inherit modifier terminal menu;

      left = "l";
      right = "semicolon";
      up = "j";
      down = "k";

      assigns = {
        "${shellWs}" = [{ app_id = "term"; }];
        "${editorWs}" = [{ app_id = "Emacs"; }];
        "${browserWs}" = [
          { app_id = "Google-chrome"; }
          { app_id = "Firefox"; }
          { app_id = "Brave"; }
          { app_id = "chromium"; }
        ];

        "${triviaWs}" = [
          { app_id = "skype"; }
          { app_id = "slack"; }
          { app_id = "discord"; }
          { app_id = "telegram-desktop"; }
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

      focus = {
        followMouse = false;
        wrapping = "yes";
      };

      keybindings = lib.mkOptionDefault {
        "${modifier}+x" = "kill";

        "${modifier}+1" = "workspace number ${shellWs}";
        "${modifier}+2" = "workspace number ${editorWs}";
        "${modifier}+3" = "workspace number ${browserWs}";
        "${modifier}+0" = "workspace number ${triviaWs}";

        "${modifier}+Shift+1" = "move container to workspace number ${shellWs}";
        "${modifier}+Shift+2" = "move container to workspace number ${editorWs}";
        "${modifier}+Shift+3" = "move container to workspace number ${browserWs}";
        "${modifier}+Shift+0" = "move container to workspace number ${triviaWs}";

        "Print" = "exec flameshot gui --raw | ${pkgs.wl-clipboard}/bin/wl-copy";
        #"Print" = "exec flameshot gui";

        "Control+Alt+h" = "exec ${copyq} toggle";

        # Hide dunst notification.
        "Control+Shift+space" = "exec ${dunstCloseNotification}";
      };

      input."type:keyboard" = {
        xkb_variant = "intl";
        xkb_model = "pc105";
        xkb_layout = "us";
        xkb_options = "caps:super";
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
          criteria = { app_id = "fzf-menu"; };
          command = "border none, sticky enable, floating enable, focus";
        }

        {
          criteria = { title = ".*CopyQ"; };
          command = "floating enable, sticky enable, floating enable, focus";
        }

        {
          criteria = { class = "xwaylandvideobridge"; };
          command = "opacity 0.0, floating enable";
        }
      ];

      startup = [
        { command = "pa-applet"; }
      ] ++ pkgs.lib.lists.optionals (hostname == "micro") [
        { command = "Discord"; }
        { command = editor; }
        { command = terminal; }
        { command = "brave"; }
        { command = "skypeforlinux"; }
        { command = "slack"; }
        { command = "telegram-desktop"; }
        { command = "${pkgs.lib.getExe pkgs.sway-audio-idle-inhibit}"; }
      ];
    };

    systemd.xdgAutostart = true;

    wrapperFeatures = {
      gtk = true;
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

  # clipboard manager. keeps the contents once the original program quits.
  services.copyq = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "sway-session.target";
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock --grace 10";
      }
    ];
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      fade-in = "2";
      screenshots = true;
      effect-pixelate = "10";
      effect-greyscale = true;
    };
  };

  xdg.portal = {
    enable = true;
    config.sway = {
      default = [ "gtk" ];

      # for flameshot to work
      # https://github.com/flameshot-org/flameshot/issues/3363#issuecomment-1753771427
      "org.freedesktop.impl.portal.Screencast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      qt6Packages.xwaylandvideobridge
    ];
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    iosevka-bin
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.fira-code
    font-awesome

    xdg-utils
    fzf
    pavucontrol
  ];
}
