# Ahead of nixpkgs (0.0.45) on an upstream nightly, carrying my changes
# rebased onto that tag. Upstream closed the first two without merging:
# https://github.com/pingdotgg/t3code/pull/14957
# https://github.com/pingdotgg/t3code/pull/13755
# https://github.com/pingdotgg/t3code/pull/13903
{
  pkgs,
  # The nixpkgs t3code to build on; an overlay must pass `prev.t3code`.
  t3code ? pkgs.t3code,
}:

let
  browser = pkgs.callPackage ./chrome-headless-shell.nix { };

  unwrapped = t3code.unwrapped.overrideAttrs (
    finalAttrs: old: {
      version = "0.1.1-nightly.20261018.3315";
      src = old.src.override {
        tag = "v${finalAttrs.version}";
        hash = "sha256-lxIVl94+VlqX/j9ErCoJlkWZtGyIV2tiHH28pFjbhwk=";
      };
      patches = (old.patches or [ ]) ++ [
        ./context-window-indicator.patch
        ./direnv-environment.patch
        ./shell-history.patch
      ];
      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs)
          pname
          pnpmWorkspaces
          src
          version
          ;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-/eGBFRnzW2uiisxw5GsvF892S5TsTOgo2JYnZ77VYBI=";
      };
      postPatch = (old.postPatch or "") + ''
        grep -qF 'const VERSION = "${browser.version}";' apps/server/src/preview/PreviewBrowser.ts \
          || { echo "chrome-headless-shell.nix is not at T3's pinned browser version" >&2; exit 1; }
        ${pkgs.lib.concatMapStrings (archive: ''
          grep -qF '"${archive.sha256}"' apps/server/src/preview/PreviewBrowser.ts \
            || { echo "chrome-headless-shell.nix has a stale ${archive.platform} hash" >&2; exit 1; }
        '') (builtins.attrValues browser.archives)}
      '';
      # node-pty 1.2 skips node-gyp when it ships a prebuild for the
      # host, and that prebuild cannot find libstdc++ on NixOS.
      env = (old.env or { }) // {
        npm_config_build_from_source = "true";
      };
    }
  );
in
(t3code.override {
  t3code-unwrapped = unwrapped;
  t3code-resource-monitor = t3code.resourceMonitor.override {
    t3code-unwrapped = unwrapped;
  };
}).overrideAttrs
  (old: {
    # Device support npm-installs expo-device-hub and agent-device at runtime.
    # Suffix so a project's own Node still wins in agent shells.
    buildCommand = old.buildCommand + ''
      for program in "$out/bin"/*; do
        wrapProgram "$program" --suffix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}
      done
    '';
    passthru = old.passthru // {
      inherit browser;
    };
  })
