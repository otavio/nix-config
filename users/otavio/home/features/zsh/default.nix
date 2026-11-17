{
  config,
  lib,
  pkgs,
  ...
}:
let
  cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";

  nix-differ = pkgs.writeScriptBin "nix-differ" ''
    nix run nixpkgs#nix-diff /run/current-system $(nix eval .#nixosConfigurations.$(hostname).config.system.build.toplevel --raw)
  '';
in
{
  home = {
    packages = with pkgs; [
      tree
      fd
      nix-differ
      zsh-completions
      nettools # for ifconfig
      psmisc # for killall
    ];
    file."${config.programs.zsh.dotDir}/zfunc" = {
      source = ./zfunc;
      recursive = true;
    };
  };
  programs = {
    direnv = {
      enable = true;

      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
    bat.enable = true;
    fzf = {
      enable = true;

      tmux.enableShellIntegration = true;
    };
    eza.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      syntaxHighlighting.enable = true;

      dotDir = "${config.xdg.configHome}/zsh";
      history.path = "${config.xdg.stateHome}/zsh_history";
      # .zshenv so non-interactive `zsh -c` (as used by AI harnesses) gets it:
      # unmatched globs pass through literally, `===` is not `=cmd` expansion,
      # and unquoted variables word-split like bash (non-interactive only).
      envExtra = ''
        setopt NO_NOMATCH
        unsetopt EQUALS
        [[ -o interactive ]] || setopt SH_WORD_SPLIT
      '';
      initContent = lib.mkOrder 500 ''
        stty -ixon

        # Nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix.sh'
        fi

        export NIX_PATH=$HOME/.nix-defexpr/channels:$NIX_PATH
        # End Nix

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
        BASE16_SHELL_PATH="${pkgs.base16-shell}/share/base16-shell"
        [ -n "$PS1" ] && \
            [ -s "$BASE16_SHELL_PATH/profile_helper.sh" ] && \
                source "$BASE16_SHELL_PATH/profile_helper.sh"
        [ -n "$PS1" ] && set_theme ayu-dark

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

        what-is-my-ip() {
            echo "My IP: $(curl -s ifconfig.me)"
        }

        keys-close() {
            echo Unloading GPG and SSH keys
            gpgconf --kill gpg-agent
            echo -n Closing encrypted partition...
            mountpoint -q /tmp/otavio/keys && { sudo umount /tmp/otavio/keys || { echo ERROR; return 1; }; }
            local majmin=$(lsblk -dno MAJ:MIN /dev/mapper/keys 2>/dev/null | tr -d ' ')
            local dm=$(basename "$(readlink -f /dev/mapper/keys)")
            if ! sudo ${cryptsetup} luksClose keys 2>/dev/null; then
                echo
                echo "WARNING: device still in use; close deferred until released by:"
                sudo sh -c "grep -l ' $majmin ' /proc/[0-9]*/mountinfo; find /proc/[0-9]*/fd -lname /dev/$dm" 2>/dev/null \
                    | cut -d/ -f3 | sort -u | xargs -r ps -o pid,unit,cmd -p | cut -c1-160
                sudo ${cryptsetup} close --deferred keys || { echo ERROR; return 1; }
                return 0
            fi
            rmdir /tmp/otavio/keys /tmp/otavio 2>/dev/null
            echo done
        }

        transfer() {
            # Easier change of service in use
            host=https://temp.sh/upload

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
                    curl --progress-bar -F "file=@$tgzfile" "$host" >> $tmpfile
                    rm -f $tgzfile
                else
                    # transfer file
                    curl --progress-bar -F "file=@$file" "$host" >> $tmpfile
                fi
            else
                # transfer pipe
                tmp=$( mktemp -t )
                dd of=$tmp 2> /dev/null
                curl --progress-bar -F "file=@$tmp" "$host" >> $tmpfile
            fi

            # cat output link
            cat $tmpfile
            echo

            # cleanup
            rm -f $tmpfile
        }

        [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

        autoload -U +X bashcompinit && bashcompinit
        source ${pkgs.bitbake-completion}/share/bitbake-completion/bitbake_completion
        fpath+=${config.programs.zsh.dotDir}/zfunc

        [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && exec startx
      '';

      shellAliases = {
        # Use bat in place of cat/less: no paging for cat, always page for less.
        cat = "bat --paging=never";
        less = "bat --paging=always";

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
  };
}
