{ pkgs, flake, ... }:

let
  # The rtk awareness document ships a verification section that only helps a
  # human debugging an install; it stays resident in every session otherwise.
  # The filter leaves the document untouched if upstream renames the heading.
  trimAwareness = hook: pkgs.runCommand "rtk-awareness-${hook}.md" { } ''
    awk '
      /^## (Installation )?Verification$/ { skip = 1; next }
      /^## / { skip = 0 }
      !skip
    ' ${pkgs.rtk.src}/hooks/${hook}/rtk-awareness.md > $out
  '';

  # The whole directory is deployed, not just the referenced file, so links
  # between these documents resolve the same way they do in the repository.
  mkInstructions = { dir, hook, indexFile }: {
    "${dir}/USER.md".source = ./USER.md;
    "${dir}/RTK.md".source = trimAwareness hook;
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
  ];

  home.packages = with pkgs; [ jq ripgrep rtk ];

  home.file =
    mkInstructions { dir = ".claude"; hook = "claude"; indexFile = "CLAUDE.md"; }
    // mkInstructions { dir = ".codex"; hook = "codex"; indexFile = "AGENTS.md"; }
    // {
      "src/nixpkgs/CLAUDE.md".source = ./projects/nixpkgs.md;
      "src/nixpkgs/AGENTS.md".source = ./projects/nixpkgs.md;
    };
}
