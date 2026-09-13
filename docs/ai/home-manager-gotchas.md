# Home Manager Gotchas

`nix flake check` exits 0 on all three of these — they only surface at runtime.

- **i3 keybindings:** `i3wm/default.nix` defines `keybindings` with
  `lib.mkOptionDefault` (priority 1500). Another module adding a binding must
  wrap it in `lib.mkOptionDefault` too; a normal-priority definition replaces
  the whole attrset instead of merging it. Verify with `nix eval` on the
  keybindings attrset and check the attribute count, not just the new key.
- **Service restarts:** `systemd.user.startServices = "sd-switch"` restarts a
  unit only when the unit file itself changes, so a daemon whose settings live
  in a separate `xdg.configFile` keeps running the old config after a switch.
  Put the config's store path in `Unit.X-Restart-Triggers` (see
  `whisrs/module.nix`).
- **Git credentials:** git reads the legacy `~/.gitconfig` *after*
  home-manager's `~/.config/git/config`, so stale entries there override it. A
  previously-run `gh auth setup-git` writes a `helper =` reset pinned to a
  `gh` store path that later gets garbage-collected, which breaks auth silently
  and falls back to `SSH_ASKPASS`. Inspect the file when changing
  `programs.git` or `programs.gh`.
