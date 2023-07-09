{
  programs.alacritty = {
    enable = true;
    settings = {
      env.term = "alacritty";
    };
  };

  home.sessionVariables = {
    TERMINAL = "alacritty";
  };
}
