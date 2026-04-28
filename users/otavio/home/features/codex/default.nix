{ inputs, pkgs, ... }:

let
  codexPackage = inputs.codex-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  configFile = (pkgs.formats.toml { }).generate "codex-config.toml" {
    model = "gpt-5.3-codex";
    model_reasoning_effort = "high";
  };
in
{
  home.packages = with pkgs; [
    bubblewrap
    codexPackage
    ripgrep
  ];

  xdg.configFile."codex/config.toml".source = configFile;
}
