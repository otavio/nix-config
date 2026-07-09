# herdr owns config.toml (it writes onboarding, theme, and keybinding state), so
# we merge managed keybindings into it on activation rather than replacing it.
# Add a binding by appending to `keybinds`; dedup is by `key`.
{ lib, pkgs, ... }:

let
  keybinds = [
    {
      key = "prefix+h";
      command = "herdr plugin action invoke worktree-split --plugin hunk.diff";
    }
  ];

  managed = builtins.toJSON keybinds;
in
{
  home.activation.herdrKeybinds = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"
    mkdir -p "$(dirname "$cfg")"
    [ -e "$cfg" ] || : > "$cfg"
    ${lib.getExe pkgs.yj} -tj < "$cfg" \
      | ${lib.getExe pkgs.jq} --argjson managed ${lib.escapeShellArg managed} '
          (.keys.command // []) as $existing
          | ($managed | map(.key)) as $keys
          | .keys.command =
              (($existing | map(select(.key as $k | ($keys | index($k)) | not))) + $managed)
        ' \
      | ${lib.getExe pkgs.yj} -jt > "$cfg.tmp"
    mv "$cfg.tmp" "$cfg"
  '';
}
