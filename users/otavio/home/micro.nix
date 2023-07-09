{ pkgs, ... }:

{
  imports = [
    ./global
    ./features/emacs
    ./features/flameshot
    ./features/gpg
    ./features/ossystems-specific

    ./base.nix
    ./zsh.nix
    ./desktop.nix
    ./gtk.nix
    ./i3.nix
  ];

  home.packages = [
    (pkgs.writeShellApplication {
      name = "open-windoze";
      runtimeInputs = with pkgs; [ virt-viewer ];
      text = ''
        virsh -c qemu:///system list --all --state-running --name | grep -q "Windoze" \
          || virsh -c qemu:///system start Windoze \
          && exec virt-viewer -f -c qemu:///system Windoze
      '';
    })
  ];
}
