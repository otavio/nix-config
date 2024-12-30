{ lib, pkgs, ... }:

{
  imports = [
    ./features/global
    ./features/alacritty
    ./features/brave
    ./features/dunst
    ./features/emacs
    ./features/flameshot
    ./features/gpg
    ./features/gtk
    ./features/swaywm
    ./features/irssi
    ./features/ossystems-specific
    ./features/unclutter
    ./features/xdg
    ./features/zathura
    ./features/zsh
  ];

  wayland.windowManager.sway.config = {
    output."LG Electronics LG ULTRAWIDE 0x01010101" = {
      modeline = "230.76  2560 2728 3000 3440  1080 1081 1084 1118  -HSync +Vsync";
      background = "#000000 solid_color";
    };
  };

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
    skypeforlinux
    slack
    tdesktop
  ];
}
