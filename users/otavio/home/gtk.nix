{ config, lib, pkgs, ... }:

{
  gtk = {
    enable = true;

    theme.name = "Adwaita-dark";
    font.name = "Ubuntu 12";
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };

    gtk2.extraConfig = ''
      gtk-key-theme-name = "Emacs"
      gtk-cursor-theme-name = capitaine-cursors;

      binding "vbe-text-entry-bindings" {
        unbind "<ctrl>b"
        unbind "<shift><ctrl>b"
        unbind "<ctrl>f"
        unbind "<shift><ctrl>f"
        unbind "<ctrl>w"
        bind "<alt>BackSpace" { "delete-from-cursor" (word-ends, -1) }
      }
      class "GtkEntry" binding "vbe-text-entry-bindings"
      class "GtkTextView" binding "vbe-text-entry-bindings"
    '';

    gtk3.extraConfig = {
      gtk-key-theme-name = "Emacs";
      gtk-cursor-theme-name = "capitaine-cursors";
    };

    gtk3.extraCss = ''
      /* Useless: we cannot override properly by unbinding some keys */
      /* @import url("/usr/share/themes/Emacs/gtk-3.0/gtk-keys.css"); */

      @binding-set custom-text-entry
      {
        bind "<alt>b" { "move-cursor" (words, -1, 0) };
        bind "<shift><alt>b" { "move-cursor" (words, -1, 1) };
        bind "<alt>f" { "move-cursor" (words, 1, 0) };
        bind "<shift><alt>f" { "move-cursor" (words, 1, 1) };

        bind "<ctrl>a" { "move-cursor" (paragraph-ends, -1, 0) };
        bind "<shift><ctrl>a" { "move-cursor" (paragraph-ends, -1, 1) };
        bind "<ctrl>e" { "move-cursor" (paragraph-ends, 1, 0) };
        bind "<shift><ctrl>e" { "move-cursor" (paragraph-ends, 1, 1) };

        bind "<ctrl>y" { "paste-clipboard" () };

        bind "<ctrl>d" { "delete-from-cursor" (chars, 1) };
        bind "<alt>d" { "delete-from-cursor" (word-ends, 1) };
        bind "<ctrl>k" { "delete-from-cursor" (paragraph-ends, 1) };
        bind "<alt>backslash" { "delete-from-cursor" (whitespace, 1) };
        bind "<alt>BackSpace" { "delete-from-cursor" (word-ends, -1) };

        bind "<alt>space" { "delete-from-cursor" (whitespace, 1)
                            "insert-at-cursor" (" ") };
        bind "<alt>KP_Space" { "delete-from-cursor" (whitespace, 1)
                               "insert-at-cursor" (" ")  };
      }

      entry, textview
      {
        -gtk-key-bindings: custom-text-entry;
      }

      .window-frame, .window-frame:backdrop {
        box-shadow: 0 0 0 black;
        border-style: none;
        margin: 0;
        border-radius: 0;
      }

      .titlebar {
        border-radius: 0;
      }
    '';
  };
}
