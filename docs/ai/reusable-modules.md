# Reusable Modules With Options

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
