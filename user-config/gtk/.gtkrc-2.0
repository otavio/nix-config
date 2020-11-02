gtk-key-theme-name="Emacs"
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
