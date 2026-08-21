{ config, flake, lib, pkgs, ... }:

let
  credentialGuard = import ./credential-guard.nix { inherit pkgs; };

  configDir = "${config.xdg.configHome}/opencode";

  # opencode has no environment policy of its own, so the guard has to travel
  # with the binary: the vars must already be set when it spawns a command.
  opencodePackage = pkgs.symlinkJoin {
    name = "opencode-${pkgs.opencode.version}";
    paths = [ pkgs.opencode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        ${lib.concatStringsSep " \\\n        "
          (lib.mapAttrsToList (name: value: "--set ${name} ${lib.escapeShellArg value}")
            (credentialGuard.mkAgentEnv "opencode"))}
    '';
  };

  # opencode reads AGENTS.md by itself, but it does not follow the @-references
  # the other agents expand, so the documents are named here instead.
  settings = {
    "$schema" = "https://opencode.ai/config.json";
    instructions = [
      "${configDir}/USER.md"
      "${configDir}/docs/reusable-modules.md"
    ];
  };
in
{
  home.packages = [ opencodePackage ];

  xdg.configFile = {
    "opencode/opencode.json".source =
      (pkgs.formats.json { }).generate "opencode.json" settings;

    "opencode/USER.md".source = ./USER.md;
    "opencode/docs".source = "${flake}/docs/ai";

    # RTK reaches opencode as a plugin, not as an awareness document; the
    # plugin directory is loaded at startup.
    "opencode/plugins/rtk.ts".source = "${pkgs.rtk.src}/hooks/opencode/rtk.ts";
  };
}
