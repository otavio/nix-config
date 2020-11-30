{ config, pkgs, ... }:
let
  base16-shell = pkgs.stdenv.mkDerivation {
    name = "base16-shell";
    src = pkgs.fetchFromGitHub {
      owner = "chriskempson";
      repo = "base16-shell";
      rev = "ce8e1e540367ea83cc3e01eec7b2a11783b3f9e1";
      sha256 = "1yj36k64zz65lxh28bb5rb5skwlinixxz6qwkwaf845ajvm45j1q";
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
    grml-zsh-config
    base16-shell
    bitbake-completion

    exa
  ];

  programs.bat.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".config/zsh/zfunc" = {
    source = ../nix/zsh/zfunc;
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    dotDir = ".config/zsh";
    initExtra = ''
      source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
      source ${base16-shell}/share/base16-shell/scripts/base16-default-dark.sh
      source ${bitbake-completion}/share/bitbake-completion/bitbake_completion

      r() { nix run nixpkgs.$1 -c $@ }

      keys-load() {
        if [ -z "$1" ]; then
          unset SSH_AUTH_SOCK
          echo Decriptando particao... && \
              sudo cryptsetup -v luksOpen /dev/disk/by-uuid/faae5ddb-df82-4a23-8a24-eedd6356ccff keys && \
              sudo mount /dev/mapper/keys /mnt && \
              echo done

          echo Carregando chave SSH ...
          DISPLAY="" keychain id_rsa
        fi

        [ -f $HOME/.keychain/$(hostname)-sh ] && \
          source $HOME/.keychain/$(hostname)-sh
        [ -f $HOME/.keychain/$(hostname)-sh-gpg ] && \
          source  $HOME/.keychain/$(hostname)-sh-gpg
       }

       keys-close() {
         echo Descarregando chave SSH
         keychain --stop mine
         echo -n Desligando particao encriptada...
         sudo umount /mnt > /dev/null
         sudo cryptsetup -v luksClose keys && \
         echo done
       }

       transfer() {
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
             curl --progress-bar --upload-file "$tgzfile" "https://up.sceptique.eu/$basefile.tgz" >> $tmpfile
             rm -f $tgzfile
           else
             # transfer file
             curl --progress-bar --upload-file "$file" "https://up.sceptique.eu/$basefile" >> $tmpfile
           fi
         else
           # transfer pipe
           curl --progress-bar --upload-file "-" "https://up.sceptique.eu/$file" >> $tmpfile
         fi

         # cat output link
         cat $tmpfile
         echo

         # cleanup
         rm -f $tmpfile
       }

       keys-load "not-ask"

       [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && exec startx
    '';

    initExtraBeforeCompInit = ''
      autoload -U +X compinit && compinit
      autoload -U +X bashcompinit && bashcompinit
      fpath+=~/.config/zsh/zfunc
    '';

    shellAliases = {
      l = "exa -l";
      ls = "exa";
      ll = "exa -l";
      lll = "exa -l | less";
      lla = "exa -la";
      llt = "exa -T";
      llfu = "exa -bghHliS --git";
      tb = "nc termbin.com 9999";

      # Insecure SSH and SCP aliases. I use this to connect to temporary devices
      # such as embedded devices under test or development so we don't need to
      # delete the fingerprint every time we reinstall them.
      issh = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
      iscp = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };

    history = {
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
  };
}
