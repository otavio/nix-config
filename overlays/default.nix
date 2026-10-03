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
    # Ahead of nixpkgs (0.0.42) on an upstream nightly, carrying my
    # upstream PRs rebased onto that tag:
    # https://github.com/pingdotgg/t3code/pull/14957
    # https://github.com/pingdotgg/t3code/pull/14595
    # https://github.com/pingdotgg/t3code/pull/13755
    # https://github.com/pingdotgg/t3code/pull/13903
    t3code =
      let
        unwrapped = prev.t3code.unwrapped.overrideAttrs (
          finalAttrs: old: {
            version = "0.0.46-nightly.20261003.2632";
            src = old.src.override {
              tag = "v${finalAttrs.version}";
              hash = "sha256-phC+xfp3+MR+w87N9HIaxlqah2yPizvs4S9DQAhIhhQ=";
            };
            patches = (old.patches or [ ]) ++ [
              ./t3code/context-window-indicator.patch
              ./t3code/composer-focus-caret.patch
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
              hash = "sha256-IvBYaCbOYy/5Sf5hziU9bCkrcm5SZJHwTQsXiYW7dMo=";
            };
            # node-pty 1.2 skips node-gyp when it ships a prebuild for the
            # host, and that prebuild cannot find libstdc++ on NixOS.
            env = (old.env or { }) // {
              npm_config_build_from_source = "true";
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
