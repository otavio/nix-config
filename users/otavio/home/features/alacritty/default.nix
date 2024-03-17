{
  programs.alacritty = {
    enable = true;
    settings = {
      env.term = "alacritty";
      keyboard.bindings = [
        { key = "Insert"; mods = "Shift"; action = "Paste"; }
      ];
    };
  };

  home.sessionVariables = {
    TERMINAL = "alacritty";
  };
}
