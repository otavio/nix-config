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
    # Wrapper around pinentry-qt that refuses passphrase entry inside AI
    # agents; behaves as the normal pinentry everywhere else.
    pinentry.package = guard.pinentry;
    # The stock hook also runs in non-interactive shells, which resets the
    # agent's tty to none and leaves pinentry-curses with nowhere to draw.
    enableZshIntegration = false;
    # keys-load asks for the passphrase once and presets it for the SSH keys.
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
  programs = {
    zsh.initContent = ''
      export GPG_TTY=$TTY
      [[ -t 0 ]] && ${updateStartupTty} > /dev/null
    '';
    # SSH requests carry no environment of their own; see sshStartupEnv.
    ssh.settings.gpg-agent-tty.header = "Match host * exec \"${pkgs.lib.getExe guard.sshStartupEnv}\"";
    gpg.enable = true;
  };
}
