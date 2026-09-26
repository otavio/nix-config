{ inputs, pkgs, ... }:

let
  codexPackage = inputs.codex-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  herdrHooks = import ./herdr-hooks.nix { inherit inputs pkgs; };

  credentialGuard = import ./credential-guard.nix { inherit pkgs; };

  configFile = (pkgs.formats.toml { }).generate "codex-config.toml" {
    model = "gpt-5.3-codex";
    model_reasoning_effort = "high";
    features.hooks = true;
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
      codexPackage
    ];
    file.".codex/hooks.json".source = hooksFile;
  };
  xdg.configFile."codex/config.toml".source = configFile;
}
