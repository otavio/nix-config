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

  dataDir = name: "\${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-${name}";

  # Obsidian creates its CLI socket in $XDG_RUNTIME_DIR, so instances that
  # share it take over each other's socket. The base is fixed, not read from
  # $XDG_RUNTIME_DIR, because inside an instance that variable is the
  # per-vault directory.
  runtimeDir = name: "/run/user/$UID/obsidian-${name}";

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
            data="${dataDir name}"
            run="${runtimeDir name}"

            mkdir -p "$data"
            if [ ! -e "$data/obsidian.json" ]; then
              printf '{"vaults":{"${vaultId}":{"path":"%s","ts":0,"open":true}}}\n' "$vault" > "$data/obsidian.json"
            fi

            # Set by Electron-based terminals (VS Code, T3); Obsidian would start
            # as plain Node instead of opening a window.
            unset ELECTRON_RUN_AS_NODE

            [ -d "$run" ] || mkdir -m 700 "$run"
            if [ -z "''${PULSE_SERVER:-}" ] && [ -S "/run/user/$UID/pulse/native" ]; then
              export PULSE_SERVER="unix:/run/user/$UID/pulse/native"
            fi
            export XDG_RUNTIME_DIR="$run"

            cd "$vault"
            # shellcheck disable=SC2016
            exec nix develop --command bash -c \
              'exec "''${OBSIDIAN_APP:?the vault devshell must set OBSIDIAN_APP}" "$@"' \
              obsidian --user-data-dir="$data" "$@"
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

  # Sends CLI commands to the running instance of one vault. It never starts
  # the app: a CLI call that finds no instance makes Obsidian open a window.
  cli = pkgs.writeShellApplication {
    name = "obsidian";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      names=(${lib.concatStringsSep " " (lib.attrNames vaults)})
      declare -A paths=(
        ${lib.concatStrings (lib.mapAttrsToList (n: v: ''[${n}]="$HOME/${v.path}" '') vaults)}
      )
      declare -A data=(
        ${lib.concatStrings (lib.mapAttrsToList (n: _: ''[${n}]="${dataDir n}" '') vaults)}
      )
      declare -A run=(
        ${lib.concatStrings (lib.mapAttrsToList (n: _: ''[${n}]="${runtimeDir n}" '') vaults)}
      )

      die() {
        code=$1
        shift
        echo "obsidian: $*" >&2
        exit "$code"
      }

      # Chromium rewrites its process title, so the arguments can be joined by
      # spaces instead of NULs. Data dirs and store paths have no spaces.
      args_of() {
        tr '\0 ' '\n' <"/proc/$1/cmdline"
      }

      # Electron's SingletonLock points to "<host>-<pid>" of the main process.
      instance_pid() {
        local lock pid
        lock=$(readlink "''${data[$1]}/SingletonLock" 2>/dev/null) || return 1
        pid=''${lock##*-}
        [ -r "/proc/$pid/cmdline" ] || return 1
        args_of "$pid" | grep -qxF -- "--user-data-dir=''${data[$1]}" || return 1
        echo "$pid"
      }

      vault=""
      if [ -n "''${OBSIDIAN_VAULT:-}" ]; then
        [ -n "''${paths[$OBSIDIAN_VAULT]+set}" ] ||
          die 2 "unknown vault '$OBSIDIAN_VAULT'; use one of: ''${names[*]}"
        vault=$OBSIDIAN_VAULT
      else
        for n in "''${names[@]}"; do
          case "$PWD/" in "''${paths[$n]}"/*) vault=$n ;; esac
        done
      fi

      if [ -z "$vault" ]; then
        running=()
        for n in "''${names[@]}"; do
          if instance_pid "$n" >/dev/null; then running+=("$n"); fi
        done
        case ''${#running[@]} in
          0) die 1 "no Obsidian vault is running; start one of: ''${names[*]/#/obsidian-}" ;;
          1) vault=''${running[0]} ;;
          *) die 2 "several Obsidian vaults are running: ''${running[*]}; run again with OBSIDIAN_VAULT=<name>, or from inside the vault directory" ;;
        esac
      fi

      pid=$(instance_pid "$vault") ||
        die 1 "the '$vault' vault is not running; start it with obsidian-$vault"

      # Use the build of the running instance, so the client matches it.
      app=""
      while IFS= read -r arg; do
        case "$arg" in */share/obsidian/app.asar) app="''${arg%/share/obsidian/app.asar}/bin/obsidian" ;; esac
      done < <(args_of "$pid")
      [ -x "$app" ] || die 1 "cannot find the Obsidian build of process $pid"

      unset ELECTRON_RUN_AS_NODE
      export XDG_RUNTIME_DIR="''${run[$vault]}"
      exec "$app" --user-data-dir="''${data[$vault]}" "$@"
    '';
  };
in
{
  home.packages = [
    icons
    cli
  ]
  ++ lib.mapAttrsToList mkWrapper vaults;
}
