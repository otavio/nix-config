{ config, pkgs, ... }:
let
  base16-shell = pkgs.stdenv.mkDerivation {
    name = "base16-shell";
    src = pkgs.fetchFromGitHub {
      owner = "base16-project";
      repo = "base16-shell";
      rev = "41848241532fd60cdda222cc8f7b2bbead9fb50d";
      sha256 = "sha256-rkgH8J6RgI3ej04z4gPFHMabaBRZKeaXIHhk0HxXMHo=";
    };

    installPhase = ''
      mkdir -p $out/share/base16-shell
      cp -r * $out/share/base16-shell/
    '';
  };

  bitbake-completion = pkgs.stdenv.mkDerivation {
    name = "bitbake-completion";
    src = pkgs.fetchFromGitHub {
      owner = "lukaszgard";
      repo = "bitbake-completion";
      rev = "95e15443b692ebee60a3260b7018e51d2b7716ce";
      sha256 = "0i3ka8n1y1glx6zws109rkqrwfaxmk4asa085cf0nn5j3ynlss76";
    };

    installPhase = ''
      mkdir -p $out/share/bitbake-completion
      cp -r * $out/share/bitbake-completion/
    '';
  };
in
{
  home.packages = with pkgs; [
    zsh-completions
  ];

  programs.direnv = {
    enable = true;

    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;
  programs.fzf = {
    enable = true;

    tmux.enableShellIntegration = true;
  };

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  home.file.".config/zsh/zfunc" = {
    source = ./zsh/zfunc;
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    enableSyntaxHighlighting = true;

    dotDir = ".config/zsh";
    envExtra = ''
      # Nix
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix.sh'
      fi

      export NIX_PATH=$HOME/.nix-defexpr/channels:$NIX_PATH
      # End Nix
    '';

    initExtraFirst = ''
      source ${pkgs.grml-zsh-config}/etc/zsh/zshrc

      # Prompt modifications.
      #
      # In current grml zshrc, changing `$PROMPT` no longer works,
      # and `zstyle` is used instead, see:
      # https://unix.stackexchange.com/questions/656152/why-does-setting-prompt-have-no-effect-in-grmls-zshrc

      # Disable the grml `sad-smiley` on the right for exit codes != 0;
      # it makes copy-pasting out terminal output difficult.
      # Done by setting the `items` of the right-side setup to the empty list
      # (as of writing, the default is `items sad-smiley`).
      # See: https://bts.grml.org/grml/issue2267
      zstyle ':prompt:grml:right:setup' items

      # Add nix-shell indicator that makes clear when we're in nix-shell.
      # Described in: http://bewatermyfriend.org/p/2013/003/
      nix_shell_prompt() {
          REPLY=''${IN_NIX_SHELL+"(nix-shell)"}
      }
      grml_theme_add_token nix-shell-indicator -f nix_shell_prompt '%F{magenta}' '%f'

      source ${pkgs.kube-ps1}/share/kube-ps1/kube-ps1.sh
      kube_ps1_prompt() {
        command -v kubectl >/dev/null && kubeon || kubeoff
        REPLY=''$(kube_ps1)
      }
      grml_theme_add_token kube-ps1-indicator -f kube_ps1_prompt "" '%f'

      zstyle ':prompt:grml:left:setup' items rc change-root user at host path vcs \
                                             nix-shell-indicator kube-ps1-indicator \
                                             percent

      # Base16 Shell
      BASE16_SHELL_PATH="${base16-shell}/share/base16-shell"
      [ -n "$PS1" ] && \
          [ -s "$BASE16_SHELL_PATH/profile_helper.sh" ] && \
              source "$BASE16_SHELL_PATH/profile_helper.sh"
      [ -n "$PS1" ] && set_theme ayu-dark
    '';

    initExtra = ''
      source ${bitbake-completion}/share/bitbake-completion/bitbake_completion

      # Workaround to 'flakes problems related to # and zsh'
      # See: https://github.com/NixOS/nix/issues/4686
      unsetopt extendedGlob

      # Fix bad color choice for comment style
      # See: https://github.com/zsh-users/zsh-syntax-highlighting/issues/510
      typeset -gA ZSH_HIGHLIGHT_STYLES
      export ZSH_HIGHLIGHT_STYLES[comment]=fg=8,bold

      # Use emacs as default editor.
      export ALTERNATE_EDITOR=""
      export EDITOR="emacs -nw" # $EDITOR opens in terminal
      export VISUAL="emacs"     # $VISUAL opens in GUI mode

      keys-load() {
          if [ -z "$1" ]; then
              unset SSH_AUTH_SOCK
              echo Decriptando particao...
              sudo cryptsetup -v luksOpen /dev/disk/by-uuid/faae5ddb-df82-4a23-8a24-eedd6356ccff keys && \
                  sudo mount /dev/mapper/keys /mnt && \
                  echo done || echo ERROR

              echo Carregando chave SSH ...
              DISPLAY="" keychain --agents gpg,ssh id_rsa id_ed25519 EB70FEF3CDFC6E4F 306736ED8C77E0D5
          fi

          [ -f $HOME/.keychain/$(hostname)-sh ] && source $HOME/.keychain/$(hostname)-sh
          [ -f $HOME/.keychain/$(hostname)-sh-gpg ] && source  $HOME/.keychain/$(hostname)-sh-gpg
      }

      keys-close() {
          echo Descarregando chave SSH
          keychain --stop mine
          echo -n Desligando particao encriptada...
          sudo umount /mnt > /dev/null
          sudo cryptsetup -v luksClose keys && \
              echo done || echo ERROR
      }

      transfer() {
          # Easier change of service in use
          host=https://transfer.sh

          curl --version 2>&1 > /dev/null
          if [ $? -ne 0 ]; then
              echo "Could not find curl."
              return 1
          fi

          # check arguments
          if [ $# -eq 0 ]; then
              echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"
              return 1
          fi

          # get temporarily filename, output is written to this file show progress can be showed
          tmpfile=$( mktemp -t transferXXX )

          # upload stdin or file
          file=$1

          if tty -s; then
              basefile=$(basename "$file" | sed -e 's/[^a-zA-Z0-9._-]/-/g')

              if [ ! -e $file ]; then
                  echo "File $file doesn't exists."
                  return 1
              fi

              if [ -d $file ]; then
                  # zip directory and transfer
                  tgzfile=$( mktemp -t transferXXX.tgz )
                  cd $(dirname $file) && tar czf $tgzfile $(basename $file)
                  curl --progress-bar --upload-file "$tgzfile" "$host/$basefile.tgz" >> $tmpfile
                  rm -f $tgzfile
              else
                  # transfer file
                  curl --progress-bar --upload-file "$file" "$host/$basefile" >> $tmpfile
              fi
          else
              # transfer pipe
              curl --progress-bar --upload-file "-" "$host/$file" >> $tmpfile
          fi

          # cat output link
          cat $tmpfile
          echo

          # cleanup
          rm -f $tmpfile
             }

      keys-load "not-ask"

      [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

      [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && exec startx
    '';

    initExtraBeforeCompInit = ''
      autoload -U +X bashcompinit && bashcompinit
      fpath+=~/.config/zsh/zfunc
    '';

    shellAliases = {
      # Paste from command line.
      tb = "nc termbin.com 9999";

      # Insecure SSH and SCP aliases. I use this to connect to temporary devices
      # such as embedded devices under test or development so we don't need to
      # delete the fingerprint every time we reinstall them.
      issh = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
      iscp = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };

    history = {
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
  };
}
