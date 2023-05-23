{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "screen-256color";
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    tmuxp.enable = true;

    plugins = with pkgs; [
      tmuxPlugins.tmux-fzf
      tmuxPlugins.prefix-highlight
      tmuxPlugins.copycat
      tmuxPlugins.fzf-tmux-url
      {
        # Until update goes in release channel we need to package it ourselves.
        plugin = tmuxPlugins.mkTmuxPlugin {
          pluginName = "catppuccin";
          version = "unstable-2023-04-03";
          src = fetchFromGitHub {
            owner = "catppuccin";
            repo = "tmux";
            rev = "4e48b09a76829edc7b55fbb15467cf0411f07931";
            sha256 = "sha256-bXEsxt4ozl3cAzV3ZyvbPsnmy0RAdpLxHwN82gvjLdU=";
          };
          postInstall = ''
            sed -i -e 's|''${PLUGIN_DIR}/catppuccin-selected-theme.tmuxtheme|''${TMUX_TMPDIR}/catppuccin-selected-theme.tmuxtheme|g' $target/catppuccin.tmux
          '';
        };
        extraConfig = ''
          set -g @catppuccin_flavour "mocha"
          set -g @catppuccin_host "on"
          set -g @catppuccin_left_separator "█"
          set -g @catppuccin_right_separator "█"
        '';
      }
    ];

    extraConfig = ''
      set -sg terminal-overrides ",*:RGB"

      # Repeat key press automatically
      set-option -g repeat-time 1000

      # Easier and faster switching between next/prev window
      bind C-p previous-window
      bind C-n next-window

      # Key bindings for horizontal and vertical panes
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Open new window and new panel at current directory
      bind C new-window -c "#{pane_current_path}"

      # Swap Window
      bind-key -r "<" swap-window -t -1
      bind-key -r ">" swap-window -t +1
    '';
  };

  home.file.".tmuxp" = { source = ./tmux/tmuxp; recursive = true; };
}
