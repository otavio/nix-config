{ inputs, ... }:
{
  imports = [
    inputs.claude-code-overlay.homeManagerModules.default
  ];

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    settings = {
      permissions = {
        allow = [
          "Bash(find:*)"
          "Bash(ls:*)"
          "Bash(tree:*)"
          "Bash(cat:*)"
          "Bash(git config:*)"
          "Bash(git commit:*)"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:mynixos.com)"
          "WebSearch"
        ];
      };
    };
  };
}
