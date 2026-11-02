{
  config,
  lib,
  pkgs,
  ...
}:

let
  herdrHooks = import ./herdr-hooks.nix { inherit pkgs; };

  credentialGuard = import ./credential-guard.nix { inherit pkgs; };

  configPath = "${config.home.homeDirectory}/.codex/config.toml";
  deployedMarker = "${config.xdg.stateHome}/nix-config/codex-config";

  configFile = (pkgs.formats.toml { }).generate "codex-config.toml" {
    model_reasoning_effort = "high";
    features = {
      hooks = true;
      apps = false;
      plugins = false;
      remote_plugin = false;
    };
    shell_environment_policy.set = credentialGuard.mkAgentEnv "codex";
  };

  hooksFile = (pkgs.formats.json { }).generate "codex-hooks.json" {
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "bash ${herdrHooks}/codex-hook.sh session";
            timeout = 10;
          }
        ];
      }
    ];
  };
in
{
  home = {
    packages = with pkgs; [
      bubblewrap
      codex
    ];
    file.".codex/hooks.json".source = hooksFile;
    activation.codexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ ! -f ${lib.escapeShellArg configPath} ] \
        || [ -L ${lib.escapeShellArg configPath} ] \
        || [ "$(readlink ${lib.escapeShellArg deployedMarker} 2>/dev/null)" \
             != ${lib.escapeShellArg configFile} ]; then
        run rm -f ${lib.escapeShellArg configPath}
        run install -Dm600 ${lib.escapeShellArg configFile} \
          ${lib.escapeShellArg configPath}
      fi
      run mkdir -p ${lib.escapeShellArg (builtins.dirOf deployedMarker)}
      run ln -sfn ${lib.escapeShellArg configFile} \
        ${lib.escapeShellArg deployedMarker}
    '';
  };
}
