{ pkgs, ... }:

let
  guard = import ../ai-assistants/credential-guard.nix { inherit pkgs; };
in
{

  services.gpg-agent = {
    enable = true;
    # Wrapper around pinentry-curses that refuses passphrase entry inside AI
    # agents; behaves as the normal curses pinentry everywhere else.
    pinentry.package = guard.pinentry;
  };

  programs.gpg.enable = true;
}
