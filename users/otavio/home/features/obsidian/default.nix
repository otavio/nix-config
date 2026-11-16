{ lib, pkgs, ... }:

let
  vaults = {
    personal = {
      title = "Personal Wiki";
      path = "src/personal";
    };
    ossystems = {
      title = "O.S. Systems Notes";
      path = "src/notes";
    };
  };

  # Only the icons; the app itself comes from each vault's devshell.
  icons = pkgs.runCommandLocal "obsidian-icons" { } ''
    mkdir -p $out/share
    cp -r ${pkgs.obsidian}/share/icons $out/share/icons
  '';

  # Obsidian is single-instance per user data dir; a separate dir per vault
  # keeps each one running in its own devshell instead of handing off to
  # whichever instance started first.
  mkWrapper =
    name: vault:
    let
      bin = "obsidian-${name}";
      vaultId = builtins.substring 0 16 (builtins.hashString "sha256" name);
    in
    pkgs.symlinkJoin {
      name = bin;
      paths = [
        (pkgs.writeShellApplication {
          name = bin;
          text = ''
            vault="$HOME/${vault.path}"
            data="''${XDG_CONFIG_HOME:-$HOME/.config}/${bin}"

            mkdir -p "$data"
            if [ ! -e "$data/obsidian.json" ]; then
              printf '{"vaults":{"${vaultId}":{"path":"%s","ts":0,"open":true}}}\n' "$vault" > "$data/obsidian.json"
            fi

            # Set by Electron-based terminals (VS Code, T3); Obsidian would start
            # as plain Node instead of opening a window.
            unset ELECTRON_RUN_AS_NODE

            cd "$vault"
            exec nix develop --command obsidian --user-data-dir="$data" "$@"
          '';
        })
        (pkgs.makeDesktopItem {
          name = bin;
          desktopName = "Obsidian (${vault.title})";
          exec = "${bin} %u";
          icon = "obsidian";
          categories = [ "Office" ];
        })
      ];
    };
in
{
  home.packages = [ icons ] ++ lib.mapAttrsToList mkWrapper vaults;
}
