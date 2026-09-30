{ inputs }:

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
    # Ahead of nixpkgs (0.0.42) on an upstream preview, carrying my open
    # upstream PRs rebased onto that tag:
    # https://github.com/pingdotgg/t3code/pull/12095
    # https://github.com/pingdotgg/t3code/pull/11594
    # https://github.com/pingdotgg/t3code/pull/13708
    # https://github.com/pingdotgg/t3code/pull/13734
    # https://github.com/pingdotgg/t3code/pull/13755
    # https://github.com/pingdotgg/t3code/pull/13903
    t3code =
      let
        unwrapped = prev.t3code.unwrapped.overrideAttrs (
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
              ./t3code/shell-history.patch
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
  };

  llm-agents = final: _: {
    inherit (inputs.llm-agents.packages.${final.stdenv.hostPlatform.system})
      claude-code
      codex
      herdr
      hunk
      opencode
      rtk
      ;
  };
}
