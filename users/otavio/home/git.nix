{ pkgs, ... }:
{
  home.file = {
    ".gitaliases".source = ./git/aliases;
    ".patman".source = ./git/patman;
  };

  home.packages = with pkgs; [
    git-review
    git-secret
    gitRepo
    gh
    patman
  ];

  programs.git = {
    enable = true;

    userName = "Otavio Salvador";
    userEmail = "otavio@ossystems.com.br";

    aliases = {
      st = "status";
      wlog = "log --color-words";
      wdiff = "diff --color-words";
      wshow = "show --color-words";
      signoff-rebase = "!GIT_SEQUENCE_EDITOR='sed -i -re s/^pick/e/' sh -c 'git rebase -i $1 && while git rebase --continue; do git commit --amend --signoff --no-edit; done' -";
    };

    delta = {
      enable = true;
      options.syntax-theme = "base16-256";
    };

    ignores = [ ".direnv" ];

    extraConfig = {
      pull = { rebase = true; };
      rebase = {
        autoStash = true;
        autoSquash = true;
        abbreviateCommands = true;
        missingCommitsCheck = "warn";
      };
    };
  };
}
