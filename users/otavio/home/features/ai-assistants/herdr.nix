{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # herdr owns its state files and rewrites them at runtime, so managed entries
  # are merged in on activation rather than replacing the files. `path` locates
  # the array inside the file — empty for a top-level JSON array — and the
  # format follows from the file name.
  registry =
    {
      file,
      key,
      managed,
      path ? [ ],
    }:
    let
      json = lib.hasSuffix ".json" file;
      format = if json then "j" else "t";
      # A missing JSON registry starts as an empty array. TOML's empty document
      # is the empty file, since a bare `{}` is not valid TOML.
      init = if json then ''printf '%s' '[]' > "$target"'' else '': > "$target"'';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="''${XDG_CONFIG_HOME:-$HOME/.config}/${file}"
      mkdir -p "$(dirname "$target")"
      [ -s "$target" ] || ${init}
      ${yj} -${format}j < "$target" \
        | ${jq} --argjson managed ${managedJson managed} --argjson path ${lib.escapeShellArg (builtins.toJSON path)} '
            ($managed | map(.${key})) as $keys
            | getpath($path) as $existing
            | setpath($path;
                (($existing // []) | map(select(.${key} as $k | ($keys | index($k)) | not))) + $managed)
          ' \
        | ${yj} -j${format} > "$target.tmp"
      mv "$target.tmp" "$target"
    '';

  jq = lib.getExe pkgs.jq;
  yj = lib.getExe pkgs.yj;

  managedJson = managed: lib.escapeShellArg (builtins.toJSON managed);

  keybinds = [
    {
      key = "prefix+h";
      command = "herdr plugin action invoke worktree-split --plugin hunk.diff";
    }
  ];

  # herdr installs plugins by recording a manifest path in plugins.json and
  # re-parsing it on server start, so generate that entry from the Nix store
  # rather than the daemon-backed `herdr plugin install`.
  plugins = [
    inputs.herdr-plugin-hunk
  ];

  # herdr runs each action's manifest `command` verbatim, so a bare `python3`
  # would have to sit on PATH and would collide with other python envs (e.g.
  # talon's python312) in the home-manager profile.
  patch =
    src:
    pkgs.runCommand "${src.name or "herdr-plugin"}-patched" { } ''
      cp -r ${src} $out
      chmod -R u+w $out
      sed -i \
        "s|\[\"python3\", \"\([^\"]*\)\"|[\"${lib.getExe pkgs.python3}\", \"$out/\1\"|g" \
        "$out/herdr-plugin.toml"
    '';

  # Read metadata from the unpatched source: readFile scans the patched
  # manifest's embedded store paths into the string's context, which would
  # then poison the activation script and trip Nix's store-path guard.
  mkEntry =
    src:
    let
      patched = patch src;
      manifest = builtins.fromTOML (builtins.readFile "${src}/herdr-plugin.toml");
    in
    {
      inherit (manifest) name version;
      plugin_id = manifest.id;
      manifest_path = "${patched}/herdr-plugin.toml";
      plugin_root = "${patched}";
      enabled = true;
    };
in
{
  home = {
    packages = [
      pkgs.herdr
      pkgs.hunk
      # notify-send, used by herdr's `[ui.toast] delivery = "system"` to route
      # agent-state popups to the desktop notification daemon (dunst).
      pkgs.libnotify
    ];
    activation = {
      herdrKeybinds = registry {
        file = "herdr/config.toml";
        path = [
          "keys"
          "command"
        ];
        key = "key";
        managed = keybinds;
      };
      herdrPlugins = registry {
        file = "herdr/plugins.json";
        key = "plugin_id";
        managed = map mkEntry plugins;
      };
    };
  };
}
