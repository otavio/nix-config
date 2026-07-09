# herdr installs plugins by recording a manifest path in plugins.json and
# re-parsing it on server start, so we generate that entry from the Nix store
# rather than the daemon-backed `herdr plugin install`. Add a plugin by
# appending its source to `plugins`.
{ inputs, lib, pkgs, ... }:

let
  # herdr runs each action's manifest `command` verbatim, so a bare `python3`
  # would have to sit on PATH and would collide with other python envs (e.g.
  # talon's python312) in the home-manager profile. Rewrite the manifest to an
  # absolute interpreter and script path so nothing python-related hits PATH.
  patch = src: pkgs.runCommand "${src.name or "herdr-plugin"}-patched" { } ''
    cp -r ${src} $out
    chmod -R u+w $out
    sed -i \
      "s|\[\"python3\", \"\([^\"]*\)\"|[\"${lib.getExe pkgs.python3}\", \"$out/\1\"|g" \
      "$out/herdr-plugin.toml"
  '';

  plugins = [
    inputs.herdr-plugin-hunk
  ];

  # Read metadata from the unpatched source: readFile scans the patched
  # manifest's embedded store paths into the string's context, which would
  # then poison the activation script and trip Nix's store-path guard.
  mkEntry = src:
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

  managed = builtins.toJSON (map mkEntry plugins);
in
{
  home.packages = [ pkgs.hunk ];

  home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    reg="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr/plugins.json"
    mkdir -p "$(dirname "$reg")"
    existing='[]'
    [ -e "$reg" ] && existing="$(cat "$reg")"
    printf '%s' "$existing" | ${lib.getExe pkgs.jq} \
      --argjson managed ${lib.escapeShellArg managed} \
      '($managed | map(.plugin_id)) as $ids
       | map(select(.plugin_id as $id | ($ids | index($id)) | not)) + $managed' \
      > "$reg.tmp"
    mv "$reg.tmp" "$reg"
  '';
}
