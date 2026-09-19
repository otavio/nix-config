# AI Harness Instructions

NixOS/Home Manager flake managing multiple machines and user configurations.

## Commands

```bash
# colmena is only in the devshell; drop the wrapper if you are already inside it.
nix develop --command colmena apply-local --sudo --node <hostname>  # Deploy locally
```

## Key Patterns

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
