{ config
, lib
, pkgs
, ...
}:
let
  modifier = "Mod4";

  copyq = "copyq";
  terminal = "i3-sensible-terminal --class=term";
  menu = "i3-sensible-terminal -t 'fzf-menu' --class 'fzf-menu' -e ${fzf-menu}/bin/i3-fzf-menu";

  dunstCloseNotification = "dunstctl close";

  shellWs = "1: shell ";
  editorWs = "2: editor ";
  browserWs = "3: browser ";
  triviaWs = "10: trivia ";

  fzf-menu = pkgs.writeScriptBin "i3-fzf-menu" (builtins.readFile (pkgs.replaceVars ./fzf-menu {
    fzf = "${pkgs.fzf}/bin/fzf";
  }));

  i3lockOnboard = pkgs.i3lock.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./i3lock-onboard.patch ];
  });

  lockScript = pkgs.writeShellScript "i3lock-onboard" ''
    ${i3lockOnboard}/bin/i3lock -n -c 000000 &
    lockpid=$!
    ${pkgs.onboard}/bin/onboard &
    onboardpid=$!
    (
      while kill -0 "$lockpid" 2>/dev/null; do
        for w in $(${pkgs.xdotool}/bin/xdotool search --name -- "[Oo]nboard" 2>/dev/null); do
          ${pkgs.xdotool}/bin/xdotool windowraise "$w" 2>/dev/null || true
        done
        sleep 1
      done
    ) &
    raiserpid=$!
    wait "$lockpid"
    kill "$onboardpid" "$raiserpid" 2>/dev/null || true
  '';

  # systemd 257+ marks graphical-session.target as RefuseManualStart=yes, so
  # `systemctl --user start graphical-session.target` from i3's startup is
  # rejected and units like whisrs.service / snixembed.service stay dormant.
  # Start a bridge service instead: it Wants= the target, which pulls it in as
  # a dependency (allowed despite RefuseManualStart) and BindsTo= it so the
  # bridge tracks the target's lifecycle.
  #
  # Also handle the first-login race where user@1000 hasn't finished reaching
  # its Main User Target by the time i3 runs its startup execs.
  start-graphical-session = pkgs.writeShellApplication {
    name = "i3-start-graphical-session";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      for attempt in $(seq 1 40); do
        if systemctl --user show-environment >/dev/null 2>&1; then
          echo "user systemd reachable after $attempt attempt(s)"
          exec systemctl --user start i3-session.service
        fi
        sleep 0.25
      done
      echo "user systemd not reachable after 10s; giving up" >&2
      exit 1
    '';
  };
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

      focus = {
        followMouse = false;
        wrapping = "yes";
      };

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

        "${modifier}+o" = "exec onboard";

        "${modifier}+Escape" = "exec ${pkgs.systemd}/bin/loginctl lock-session";

        "Print" = "exec flameshot-gui";

        "Control+Alt+h" = "exec ${copyq} toggle";

        "Mod1+Left" = "exec whisrs toggle";

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
          criteria = { class = "fzf-menu"; };
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

        {
          criteria = { class = "InputOutput"; };
          command = "floating enable, sticky enable, border none";
        }

        {
          criteria = { class = "Onboard"; };
          command = "floating enable, sticky enable, border none";
        }

        {
          criteria = { class = "flameshot"; };
          command = "floating enable, border pixel 0, fullscreen disable, focus";
        }
      ];

      startup = [
        {
          command = "${pkgs.systemd}/bin/systemd-cat -t i3-startup ${lib.getExe start-graphical-session}";
          notification = false;
        }
        { command = "pa-applet"; notification = true; }
        { command = "onboard"; notification = false; }
      ];
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
            block = "bluetooth";
            mac = "F0:5E:CD:E2:1C:A0";
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
    iosevka-bin
    noto-fonts
    nerd-fonts.fira-code
    font-awesome

    fzf
    i3
    onboard
    pavucontrol
    xclip
  ];

  services.screen-locker = {
    enable = true;
    inactiveInterval = 10;
    lockCmd = "${lockScript}";
  };

  dconf.settings = {
    "org/onboard".layout = "${pkgs.onboard}/share/onboard/layouts/Full Keyboard.onboard";
    "org/onboard/window".force-to-top = true;
    "org/onboard/window".docking-enabled = false;
    "org/onboard/auto-show".enabled = false;
  };

  home.file.".xinitrc".source = ./xinitrc;

  systemd.user.services.i3-session = {
    Unit = {
      Description = "i3 session bridge to graphical-session.target";
      BindsTo = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };
}
