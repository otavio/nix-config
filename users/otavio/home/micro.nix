{ pkgs, ... }:

{
  imports = [
    ./global
    ./features/alacritty
    ./features/brave
    ./features/dunst
    ./features/emacs
    ./features/flameshot
    ./features/gpg
    ./features/gtk
    ./features/ossystems-specific
    ./features/parcellite
    ./features/unclutter
    ./features/xdg
    ./features/zathura

    ./base.nix
    ./zsh.nix
    ./i3.nix
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
      name = "irssi";
      runtimeInputs = with pkgs; [ sops irssi ];
      text = ''
        LIBERACHAT_PASSWORD=$(sops --decrypt --extract '["irssi-nickserv"]' "$HOME"/src/nix-config/secrets/secrets.yaml)
        export LIBERACHAT_PASSWORD
        irssi
      '';
    })

    (writeShellApplication {
      name = "scrcpy";
      runtimeInputs = with pkgs; [ scrcpy ];
      text = ''
        scrcpy -M
      '';
    })

    anydesk

    discord
    skypeforlinux
    slack
    tdesktop
  ];

  home.file.".irssi" = {
    source = ./irssi;
    recursive = true;
  };
}
