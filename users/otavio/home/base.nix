{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    # Local scripts added to default PATH.
    (pkgs.stdenv.mkDerivation {
      name = "base-scripts";
      src = ./scripts;
      installPhase = ''
        mkdir -p $out/bin
        cp -r * $out/bin
      '';
    })

    gping
    htop
    mtr
    nnn
    tmux
    tmuxp
    tree
    xclip

    axel
    wget
    nettools # for ifconfig
    psmisc # for killall

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR

    awscli2
  ];

  services.gpg-agent.enable = true;
  programs.gpg.enable = true;
  programs.msmtp.enable = true;
  programs.ssh = {
    enable = true;

    controlMaster = "auto";
    hashKnownHosts = false;

    extraConfig = ''
      Host *.ossystems.com.br
           HostkeyAlgorithms +ssh-rsa
           PubkeyAcceptedAlgorithms +ssh-rsa

      Host *.lab.ossystems
           ForwardAgent yes
           ForwardX11 yes
           ForwardX11Trusted yes
    '';
  };

  home.sessionVariables = {
    TERMINAL = "alacritty";
    TERM = "xterm-256color";
  };

  home.file = {
    ".emacs.d" = { source = ./emacs.d; recursive = true; };
    ".yocto/site.conf".source = ./yocto/site.conf;
  };
}
