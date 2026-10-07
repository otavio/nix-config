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
    t3code = import ../packages/t3code {
      pkgs = final;
      inherit (prev) t3code;
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
