{ pkgs, ...}:
{
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      tuttieee.emacs-mcx
      bbenoist.nix
      bierner.markdown-mermaid
      yzhang.markdown-all-in-one
      oderwat.indent-rainbow
    ];

    userSettings = {
      # Editor
      editor.acceptSuggestionOnEnter = "off";
      editor.autoClosingBrackets = "always";
      editor.cursorBlinking = "smooth";
      editor.cursorSmoothCaretAnimation = true;
      editor.cursorStyle = "line";
      editor.fontFamily = "'FiraCode Nerd Font', monospace";
      editor.fontLigatures = true;
      editor.fontSize = 14;
      editor.fontWeight = "700";
      editor.formatOnPaste = true;
      editor.formatOnSave = true;
      editor.formatOnType = true;
      editor.renderFinalNewline = false;
      editor.rulers = [ 80 ];
      editor.smoothScrolling = true;
      editor.stickyTabStops = true;
      editor.suggest.preview = true;
      editor.guides.bracketPairs = true;

      # Terminal
      terminal.integrated.fontSize = 12;
      terminal.integrated.allowChords = false;
      terminal.integrated.gpuAcceleration = "on";
      terminal.integrated.cursorStyle = "line";
      terminal.integrated.cursorBlinking = true;

      # Files
      files.autoSave = "off";
      files.eol = "\n";
      files.exclude = { };
      files.insertFinalNewline = true;
      files.trimFinalNewlines = true;
      files.trimTrailingWhitespace = true;

      # Telemetry
      telemetry.telemetryLevel = "off";
      redhat.telemetry.enabled = false;

      # Updates
      update.mode = "none";

      # Spelling
      cSpell.allowCompoundWords = true;
      cSpell.spellCheckDelayMs = 1000;
      cSpell.showStatus = false;

      # Git
      git.enableStatusBarSync = false;
      git-graph.showStatusBarItem = false;

      # Languages
      ## Rust
      crates.listPreReleases = true;
      rust-analyzer.experimental.procAttrMacros = true;
      rust-analyzer.checkOnSave.command = "clippy";

      ## Nix
      nix.enableLanguageServer = true;
      nix.serverPath = "${pkgs.nil}/bin/nil";
      nixEnvSelector.nixFile = "\${workspaceRoot}/shell.nix";
      "[nix]" = { editor.tabSize = 2; };

      ## C/C++
      C_Cpp.clang_format_fallbackStyle = "LLVM";

      ## JSON
      "[json]" = { editor.tabSize = 2; };

      ## Shell
      shellformat.path = "${pkgs.shfmt}/bin/shfmt";

      ## Markdown
      markdown.preview.doubleClickToSwitchToEditor = false;
    };

    globalSnippets = {
      fixme = {
        prefix = [ "fixme" ];
        body = [ "$LINE_COMMENT FIXME: $0" ];
        description = "Insert a FIXME remark";
      };

      todo = {
        prefix = [ "todo" ];
        body = [ "$LINE_COMMENT TODO: $0" ];
        description = "Insert a TODO remark";
      };
    };
  };
}
