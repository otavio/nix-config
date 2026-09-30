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
    # Ahead of nixpkgs (0.0.42) on the orchestration v2 branch
    # (https://github.com/pingdotgg/t3code/pull/2829), which the upstream
    # preview releases are cut from, carrying my open upstream PRs rebased
    # onto it:
    # https://github.com/pingdotgg/t3code/pull/12095
    # https://github.com/pingdotgg/t3code/pull/13708
    # https://github.com/pingdotgg/t3code/pull/13734
    # https://github.com/pingdotgg/t3code/pull/13755
    # https://github.com/pingdotgg/t3code/pull/13903
    t3code =
      let
        unwrapped = prev.t3code.unwrapped.overrideAttrs (
          finalAttrs: old: {
            # The -preview.<date>.<n> shape keeps the app on the preview
            # release channel.
            version = "0.0.44-preview.20260930.0";
            src = final.fetchFromGitHub {
              owner = "pingdotgg";
              repo = "t3code";
              rev = "0fb3731eb43762459cdab350bf9a8cc247d09548";
              hash = "sha256-97b4/FSIdh//FMEM3w8CdD4+9R2baFkON+YnNGlCQnA=";
            };
            patches = (old.patches or [ ]) ++ [
              ./t3code/context-window-indicator.patch
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
              hash = "sha256-Hd2pHu58OoicTEInd4sJmy8+p6AIO3pkVubQfnNOYjc=";
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
