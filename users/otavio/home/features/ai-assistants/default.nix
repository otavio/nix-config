{ pkgs, flake, ... }:

let
  # Upstream replaced the per-agent awareness documents with shared variants.
  # The assistants here all run `rtk hook <agent>`, which rewrites commands on
  # their behalf, so take the variant that explains the condensed output
  # without telling them to type the prefix themselves.
  awareness = "${pkgs.rtk.src}/hooks/rtk-awareness-high.md";

  # The whole directory is deployed, not just the referenced file, so links
  # between these documents resolve the same way they do in the repository.
  mkInstructions = { dir, indexFile }: {
    "${dir}/USER.md".source = ./USER.md;
    "${dir}/RTK.md".source = awareness;
    "${dir}/docs".source = "${flake}/docs/ai";
    "${dir}/${indexFile}".text = "@USER.md\n@RTK.md\n";
  };
in
{
  imports = [
    ./claude.nix
    ./codex.nix
    ./opencode.nix
    ./herdr.nix
    ./herdr-plugins.nix
    ./herdr-config.nix
    ./t3code.nix
  ];
  home = {
    packages = with pkgs; [
      fd
      jq
      ripgrep
      rtk
    ];
    file =
      mkInstructions {
        dir = ".claude";
        indexFile = "CLAUDE.md";
      }
      // mkInstructions {
        dir = ".codex";
        indexFile = "AGENTS.md";
      }
      // {
        "src/nixpkgs/CLAUDE.md".source = ./projects/nixpkgs.md;
        "src/nixpkgs/AGENTS.md".source = ./projects/nixpkgs.md;
      };
  };
}
