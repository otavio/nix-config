# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

NixOS and Home Manager configuration repository managing multiple machines and user configurations using Nix flakes. Machines: micro (AMD desktop), nano (GPD Pocket 3), poirot, miss-marple.

## Commands

```bash
# Validate all configurations (runs deadnix, statix, nixpkgs-fmt)
nix flake check

# Format Nix code (nixpkgs-fmt + statix fix)
nix fmt

# Build a specific NixOS configuration
nix build ".#nixosConfigurations.micro.config.system.build.toplevel"

# Build home configuration
nix build ".#homeConfigurations.otavio@generic-x86.activationPackage"

# Build installer ISO
nix build ".#packages.x86_64-linux.installer-iso-micro"

# Deploy with Colmena
colmena apply local -n micro

# Enter development shell (provides colmena, home-manager, sops)
nix develop
```

## Architecture

```
├── flake.nix              # Main entry: inputs, outputs, nixosConfigurations
├── lib/default.nix        # Helpers: mkSystem, mkHome, mkInstallerForSystem
├── hosts/
│   ├── features/
│   │   ├── required/      # Always-included modules (console, locale, ssh, sudo, etc.)
│   │   └── optional/      # Per-machine features (desktop, docker, pipewire, talon, etc.)
│   └── <hostname>/        # Machine configs (default.nix, partitioning.nix, etc.)
├── users/<username>/
│   ├── home/<hostname>.nix   # Host-specific home-manager config
│   ├── home/features/        # Modular home features (git, emacs, zsh, i3wm, etc.)
│   └── system/               # User's system-level config (groups, shell)
├── overlays/              # Package modifications and custom packages
├── pkgs/                  # Custom package definitions
└── secrets/               # sops-nix encrypted secrets
```

## Key Patterns

**Adding features to a host:** Import from `hosts/features/optional/` in the host's `default.nix`

**Adding features to a user's home:** Import from `users/<user>/home/features/` in the host-specific home file

**Module structure:** Each feature is self-contained in a `default.nix` file

**Hardware configs:** Use `nixos-hardware` modules for CPU/GPU/storage optimizations

**Flake input style:** Always use the dotted format for follows directives, one per line: `inputs.nixpkgs.follows = "nixpkgs";`

## Dependencies

External flakes: nixpkgs (unstable), home-manager, nixos-hardware, disko (partitioning), sops-nix (secrets), emacs-overlay, talon-nix, colmena

Private: `nix-secrets` repository (requires SSH access)

## CI

Pull requests and master pushes run:
1. `nix flake check` - linting validation
2. Build all nixosConfigurations
3. Build homeConfigurations
