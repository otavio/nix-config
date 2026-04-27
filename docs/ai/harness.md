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

## Reusable Modules With Options

Modules that introduce parameterized behavior across hosts live in
`modules/nixos/<name>.nix`. red-tape auto-discovers them and exports them as
`flake.nixosModules.<name>`. Hosts receive the flake as the `flake` specialArg
and import modules via `flake.nixosModules.<name>`.

Custom options use the `my.*` namespace to avoid collisions with nixpkgs and to
make local options easy to grep. Example:

```nix
# modules/nixos/restic-r2.nix
{ config, lib, ... }:
let cfg = config.my.backup; in {
  options.my.backup.user = lib.mkOption { type = lib.types.str; };
  config.services.restic.backups.r2.paths = [ config.users.users.${cfg.user}.home ];
}

# hosts/<host>/configuration.nix
{ flake, ... }: {
  imports = [ flake.nixosModules.restic-r2 ];
  my.backup.user = "otavio";
}
```

Prefer this pattern over copy-pasting near-identical files across hosts.

## Harness Notes

If a small harness-specific instruction becomes necessary, keep it here in a
short dedicated section rather than duplicating the whole file elsewhere.
