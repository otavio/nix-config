{ lib, pkgs, ... }:

{
  imports = [
    ./generic.nix

    ./features/alacritty
    ./features/android
    ./features/claude-code
    ./features/codex
    ./features/dunst
    ./features/flameshot
    ./features/gpg
    ./features/gtk
    ./features/i3wm
    ./features/irssi
    ./features/ossystems-specific
    ./features/talon
    ./features/whisrs
    ./features/xdg
    ./features/zsh
  ];

  programs.brave.enable = true;
  programs.zathura.enable = true;

  services.unclutter.enable = true;

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ "org.pwmt.zathura.desktop" ];
  };

  xsession.windowManager.i3.config.startup = [
    { command = "discord"; notification = true; }
    { command = "emacs -nw"; notification = true; }
    { command = "i3-sensible-terminal --class=term"; notification = true; }
    { command = "brave"; notification = true; }
    { command = "slack"; notification = true; }
    { command = "Telegram"; notification = true; }
  ];

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "open-windoze";
      runtimeInputs = with pkgs; [ virt-viewer ];
      text = ''
        virsh -c qemu:///system list --all --state-running --name | grep -q "Windoze" \
          || virsh -c qemu:///system start Windoze \
          && exec virt-viewer -f -c qemu:///system Windoze
      '';
    })

    (writeShellApplication {
      name = "scrcpy";
      runtimeInputs = with pkgs; [ scrcpy ];
      text = ''
        scrcpy -M --no-audio
      '';
    })

    (writeShellApplication {
      name = "discord";
      text = ''
        XDG_SESSION_TYPE=x11 ${lib.getExe discord}
      '';
    })

    zoom-us
    slack
    telegram-desktop
  ];
}
