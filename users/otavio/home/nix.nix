{ config, pkgs, ... }: { home.packages = with pkgs; [ nixfmt rnix-lsp ]; }
