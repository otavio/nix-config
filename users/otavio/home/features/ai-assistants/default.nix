{ config, pkgs, ... }:

let
  mkInstructions = { dir, hook, indexFile }: {
    "${dir}/USER.md".source = ./USER.md;
    "${dir}/RTK.md".source = "${pkgs.rtk.src}/hooks/${hook}/rtk-awareness.md";
    "${dir}/${indexFile}".text = "@USER.md\n@RTK.md\n";
  };
in
{
  imports = [
    ./claude.nix
    ./codex.nix
  ];

  home.packages = with pkgs; [ jq ripgrep rtk superset ];

  home.file =
    mkInstructions { dir = ".claude"; hook = "claude"; indexFile = "CLAUDE.md"; }
    // mkInstructions { dir = ".codex"; hook = "codex"; indexFile = "AGENTS.md"; }
    // {
      "src/nixpkgs/CLAUDE.md".source = ./projects/nixpkgs.md;
      "src/nixpkgs/AGENTS.md".source = ./projects/nixpkgs.md;

      # Superset spawns terminals with ZDOTDIR=~/.superset/zsh; without
      # this, zsh launches its newuser wizard and skips the real init.
      ".superset/zsh/.zshrc".text = "source ${config.programs.zsh.dotDir}/.zshrc\n";
    };
}
