# CLAUDE.md

NixOS/Home Manager flake managing multiple machines and user configurations.

## Commands

```bash
nix flake check              # Validate (deadnix, statix, nixpkgs-fmt)
nix fmt                      # Format Nix code
nix develop                  # Enter dev shell (colmena, home-manager, sops)
colmena apply local -n <hostname>  # Deploy locally
```

## Architecture

```
├── hosts/features/required/      # Always-included modules
├── hosts/features/optional/      # Per-machine features
├── hosts/<hostname>/             # Machine configs
├── users/<user>/home/            # Home-manager configs
├── users/<user>/home/features/   # Modular home features
└── secrets/                      # sops-nix encrypted secrets
```

## Key Patterns

- **Host features:** Import from `hosts/features/optional/` in the host's `default.nix`
- **Home features:** Import from `users/<user>/home/features/` in host-specific home file
- **Flake inputs:** Use dotted format for follows, one per line: `inputs.nixpkgs.follows = "nixpkgs";`
