# AI Harness Instructions

NixOS/Home Manager flake managing multiple machines and user configurations.

## Commands

```bash
nix flake check              # Validate (deadnix, statix, nixpkgs-fmt)
nix fmt                      # Format Nix code
nix develop                  # Enter dev shell (colmena, home-manager, sops)
colmena apply local -n <hostname>  # Deploy locally
```

## Architecture

```text
├── hosts/features/required/      # Always-included modules
├── hosts/features/optional/      # Per-machine features
├── hosts/<hostname>/             # Machine configs
├── modules/nixos/                # Reusable NixOS modules (red-tape auto-exports)
├── users/<user>/home/            # Home-manager configs
├── users/<user>/home/features/   # Modular home features
└── secrets/                      # sops-nix encrypted secrets
```

## Key Patterns

- **Host features:** Import from `hosts/features/optional/` in the host's `default.nix`
- **Home features:** Import from `users/<user>/home/features/` in host-specific home file
- **Flake inputs:** Use dotted format for follows, one per line: `inputs.nixpkgs.follows = "nixpkgs";`

## Home Manager Gotchas

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

## Comments

Avoid useless comments. Do not add comments that restate what the code already
says or narrate a change. Only comment genuinely non-obvious rationale; put the
"why" of a change in the commit message, not inline.

## Reusable Modules With Options

Introducing parameterized behavior shared across hosts (a `my.*` option backed
by a module in `modules/nixos/`)? See
[reusable-modules.md](reusable-modules.md). Prefer this over copy-pasting
near-identical files across hosts.
