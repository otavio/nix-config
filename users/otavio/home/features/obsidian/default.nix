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

  # Obsidian is single-instance per user data dir; a separate dir per vault
  # keeps each one running in its own devshell instead of handing off to
  # whichever instance started first.
  mkWrapper =
    name: vault:
    let
      vaultId = builtins.substring 0 16 (builtins.hashString "sha256" name);
    in
    pkgs.writeShellApplication {
      name = "obsidian-${name}";
      text = ''
        vault="$HOME/${vault.path}"
        data="''${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-${name}"

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
    };
in
{
  home.packages = lib.mapAttrsToList mkWrapper vaults;

  xdg.desktopEntries = lib.mapAttrs' (
    name: vault:
    lib.nameValuePair "obsidian-${name}" {
      name = "Obsidian (${vault.title})";
      exec = "obsidian-${name} %u";
      icon = "obsidian";
      categories = [ "Office" ];
    }
  ) vaults;
}
