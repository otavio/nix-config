_:

{
  # Auto-discover custom packages from packages/*.nix
  additions = final: _:
    let
      packagesDir = ../packages;
      entries = builtins.readDir packagesDir;
      nixFiles = builtins.filter
        (n: entries.${n} == "regular" && builtins.match ".*\\.nix" n != null)
        (builtins.attrNames entries);
      scope = { pkgs = final; inherit (final) lib; };
      callPkg = path:
        let fn = import path;
        in fn (builtins.intersectAttrs (builtins.functionArgs fn) scope);
    in
    builtins.listToAttrs (builtins.map
      (file:
        let name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
        in {
          inherit name;
          value = callPkg (packagesDir + "/${file}");
        })
      nixFiles);

  modifications = _: prev: {
    # Python 3.14's configparser rejects keys containing the delimiter, and
    # timekpr 0.5.8 writes its commented config template through it, so the
    # daemon dies initialising per-user config. Upstream dropped configparser
    # in 0.5.9; drop this once the nixpkgs pin carries 0.5.10.
    timekpr = prev.timekpr.override { python3Packages = prev.python312Packages; };

    # opencode 1.18.30 bundled by bun 1.4.2 crashes on every prompt with
    # "Cannot read properties of undefined (reading 'name')" from its layer
    # resolver; the bun 1.3.13 bundle works. Drop once nixpkgs picks up
    # https://github.com/anomalyco/opencode/pull/48397 (tracked in
    # https://github.com/NixOS/nixpkgs/issues/563241).
    opencode = prev.opencode.override {
      bun = prev.bun.overrideAttrs (old: {
        version = "1.3.13";
        passthru = old.passthru // {
          sources = {
            "aarch64-darwin" = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-darwin-aarch64.zip";
              hash = "sha256-VGfj9l26Umuf6pjwzOBO+vwMY+Fpcz7Ce4dqOtMtoZA=";
            };
            "aarch64-linux" = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-aarch64.zip";
              hash = "sha256-cLrkGzkIsKEg4eWMXIrzDnSvrjuNEbDT/djnh937SyI=";
            };
            "x86_64-linux" = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-x64-baseline.zip";
              hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
            };
          };
        };
      });
    };
  };
}
