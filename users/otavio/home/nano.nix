{ pkgs, ... }:

{
  imports = [
    ./features/global
    ./features/alacritty
    ./features/brave
    ./features/dunst
    ./features/flameshot
    ./features/emacs
    ./features/gtk
    ./features/swaywm
    ./features/unclutter
    ./features/parcellite
    ./features/xdg
    ./features/zathura
    ./features/zsh
  ];


  wayland.windowManager.sway.config = {
    # Rotate screen as for proper use in GPD Pocket
    services.xserver = {
      videoDrivers = [ "intel" ];
      xrandrHeads = [
        {
          output = "DSI1";
          primary = true;
          monitorConfig = ''
            Option "Rotate" "right"
          '';
        }
      ];

      dpi = 140;
    };
  };

  home.packages = with pkgs; [
    anydesk
  ];
}
