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
    tdesktop
  ];
}
