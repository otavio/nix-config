{ config, pkgs, ... }:

let
  guard = import ../ai-assistants/credential-guard.nix { inherit pkgs; };
  updateStartupTty = "${config.programs.gpg.package}/bin/gpg-connect-agent --quiet updatestartuptty /bye";
in
{

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
    maxCacheTtl = 28800;
    maxCacheTtlSsh = 28800;
    # Wrapper around pinentry-curses that refuses passphrase entry inside AI
    # agents; behaves as the normal curses pinentry everywhere else.
    pinentry.package = guard.pinentry;
    # The stock hook also runs in non-interactive shells, which resets the
    # agent's tty to none and leaves pinentry-curses with nowhere to draw.
    enableZshIntegration = false;
  };
  programs = {
    zsh.initContent = ''
      export GPG_TTY=$TTY
      [[ -t 0 ]] && ${updateStartupTty} > /dev/null
    '';
    # SSH requests carry no tty, so point pinentry at the terminal running ssh.
    # ssh redirects stdin of Match exec to /dev/null; stderr is still the tty.
    ssh.settings.gpg-agent-tty.header = "Match host * exec \"test -t 2 && ${updateStartupTty}\"";
    gpg.enable = true;
  };
}
