# Ahead of nixpkgs (0.0.44) on an upstream nightly, carrying my upstream PRs
# rebased onto that tag:
# https://github.com/pingdotgg/t3code/pull/14957
# https://github.com/pingdotgg/t3code/pull/14595
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
      version = "0.0.46-nightly.20261007.2774";
      src = old.src.override {
        tag = "v${finalAttrs.version}";
        hash = "sha256-mkT2SVgTid58meXCHwSBMIUX1ImHaLUbnkamu3qDLPg=";
      };
      patches = (old.patches or [ ]) ++ [
        ./context-window-indicator.patch
        ./composer-focus-caret.patch
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
        hash = "sha256-4IE8MzK1AxYwd30YEn9R6XaVEr5XSFIWDdSh+X3Xdyw=";
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
    passthru = old.passthru // {
      inherit browser;
    };
  })
