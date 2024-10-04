{ pkgs, ... }:

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
    ./features/i3wm
    ./features/irssi
    ./features/ossystems-specific
    ./features/parcellite
    ./features/unclutter
    ./features/xdg
    ./features/zathura
    ./features/zsh
  ];

  # FIXME: Avoid Vulkan use in GTK rendering as it causes GPU error, see:
  # https://gitlab.freedesktop.org/drm/nouveau/-/issues/381
  home.sessionVariables.GSK_RENDERER = "gl";

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
        scrcpy -M
      '';
    })

    discord
    zoom-us
    skypeforlinux
    slack
    tdesktop
  ];
}
