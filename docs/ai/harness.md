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

## Comments

Avoid useless comments. Do not add comments that restate what the code already
says or narrate a change. Only comment genuinely non-obvious rationale; put the
"why" of a change in the commit message, not inline.

## Reusable Modules With Options

Introducing parameterized behavior shared across hosts (a `my.*` option backed
by a module in `modules/nixos/`)? See
[reusable-modules.md](reusable-modules.md). Prefer this over copy-pasting
near-identical files across hosts.
