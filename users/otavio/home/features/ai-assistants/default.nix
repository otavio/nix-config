{
  lib,
  pkgs,
  flake,
  ...
}:

let
  # Upstream replaced the per-agent awareness documents with shared variants.
  # The assistants here all run `rtk hook <agent>`, which rewrites commands on
  # their behalf, so take the variant that explains the condensed output
  # without telling them to type the prefix themselves.
  awareness = "${pkgs.rtk.src}/hooks/rtk-awareness-high.md";

  # Inlined, not `@` imports: Claude Code resolves those from the symlink's
  # target in the Nix store, where the imported files do not exist, and
  # Codex has no import syntax. concatText avoids import-from-derivation.
  # HTML comments mark where each source starts without adding headings to
  # the document structure.
  instructions = pkgs.concatText "instructions.md" (
    lib.concatLists (
      lib.intersperse [ (pkgs.writeText "separator" "\n") ] (
        map
          ({ file, name }: [
            (pkgs.writeText "marker" "<!-- Source: ${name} -->\n\n")
            file
          ])
          [
            {
              name = "USER.md";
              file = ./USER.md;
            }
            {
              name = "rtk: hooks/rtk-awareness-high.md";
              file = awareness;
            }
          ]
      )
    )
  );

  mkInstructions = { dir, indexFile }: {
    "${dir}/docs".source = "${flake}/docs/ai";
    "${dir}/${indexFile}".source = instructions;
  };
in
{
  imports = [
    ./claude.nix
    ./codex.nix
    ./opencode.nix
    ./herdr.nix
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
