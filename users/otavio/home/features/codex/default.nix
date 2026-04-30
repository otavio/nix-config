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
    rtk
  ];

  xdg.configFile."codex/config.toml".source = configFile;

  home.file.".codex/RTK.md".source = "${pkgs.rtk.src}/hooks/codex/rtk-awareness.md";
  home.file.".codex/AGENTS.md".text = "@RTK.md\n";
}
