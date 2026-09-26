_:

{
  # Auto-discover custom packages from packages/*.nix
  additions =
    final: _:
    let
      packagesDir = ../packages;
      entries = builtins.readDir packagesDir;
      nixFiles = builtins.filter (n: entries.${n} == "regular" && builtins.match ".*\\.nix" n != null) (
        builtins.attrNames entries
      );
      scope = {
        pkgs = final;
        inherit (final) lib;
      };
      callPkg =
        path:
        let
          fn = import path;
        in
        fn (builtins.intersectAttrs (builtins.functionArgs fn) scope);
    in
    builtins.listToAttrs (
      builtins.map (
        file:
        let
          name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
        in
        {
          inherit name;
          value = callPkg (packagesDir + "/${file}");
        }
      ) nixFiles
    );

  modifications = final: prev: {
    # Ahead of nixpkgs (0.0.40) on an upstream preview, carrying my open
    # upstream PRs rebased onto that tag:
    # https://github.com/pingdotgg/t3code/pull/12095
    # https://github.com/pingdotgg/t3code/pull/11594
    # https://github.com/pingdotgg/t3code/pull/13708
    # https://github.com/pingdotgg/t3code/pull/13734
    # https://github.com/pingdotgg/t3code/pull/13755
    t3code =
      let
        unwrapped =
          (prev.t3code.unwrapped.override {
            # 0.0.42 moved to Electron 44.
            electron_43 = final.electron_44;
          }).overrideAttrs
            (
              finalAttrs: old: {
                version = "0.0.43-preview.20260925.2240";
                src = old.src.override {
                  tag = "v${finalAttrs.version}";
                  hash = "sha256-hsMflvt7S71pbB8sQ13CM/pzlrsDg0+CpQpGw6FDCpE=";
                };
                patches = (old.patches or [ ]) ++ [
                  ./t3code/context-window-indicator.patch
                  ./t3code/chat-width-setting.patch
                  ./t3code/composer-focus-caret.patch
                  ./t3code/right-panel-default-width.patch
                  ./t3code/direnv-environment.patch
                ];
                pnpmDeps = final.fetchPnpmDeps {
                  inherit (finalAttrs)
                    pname
                    pnpmWorkspaces
                    src
                    version
                    ;
                  pnpm = final.pnpm_11;
                  fetcherVersion = 4;
                  hash = "sha256-7y5NCq8gPv3tTr/FyFni2VJ0feEIZNHTQYbBlJv11Hg=";
                };
                # The web build's third-party-licenses plugin downloads SPDX license
                # texts unless they are already in its cache; seed the cache so the
                # sandboxed build stays offline. Revision and IDs track
                # scripts/lib/third-party-licenses.ts and
                # third-party-licenses.config.json.
                spdxLicenses = final.fetchFromGitHub {
                  owner = "spdx";
                  repo = "license-list-data";
                  rev = "c4a7237ec8f4654e867546f9f409749300f1bf4c";
                  sparseCheckout = map (id: "json/details/${id}.json") [
                    "Apache-2.0"
                    "BSD-2-Clause"
                    "BSD-3-Clause"
                    "CC0-1.0"
                    "ISC"
                    "MIT"
                    "Unlicense"
                  ];
                  hash = "sha256-DnrdJ13M8Vf8Dq8qKlO7Ad5jXa8L9YU9PBlpp7B9BoI=";
                };
                preBuild = ''
                  mkdir -p .generated/third-party-licenses/spdx
                  cp -r --no-preserve=mode "$spdxLicenses"/json/details \
                    .generated/third-party-licenses/spdx/v3.28.0
                ''
                + old.preBuild;
              }
            );
      in
      prev.t3code.override {
        t3code-unwrapped = unwrapped;
        t3code-resource-monitor = prev.t3code.resourceMonitor.override {
          t3code-unwrapped = unwrapped;
        };
      };

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
            aarch64-darwin = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-darwin-aarch64.zip";
              hash = "sha256-VGfj9l26Umuf6pjwzOBO+vwMY+Fpcz7Ce4dqOtMtoZA=";
            };
            aarch64-linux = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-aarch64.zip";
              hash = "sha256-cLrkGzkIsKEg4eWMXIrzDnSvrjuNEbDT/djnh937SyI=";
            };
            x86_64-linux = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-linux-x64-baseline.zip";
              hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
            };
          };
        };
      });
    };
  };
}
