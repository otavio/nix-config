{ pkgs, ... }:
{
  home.file = {
    ".gitaliases".source = ./aliases;
    ".patman".source = ./patman;
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

    aliases = let git = "${pkgs.git}/bin/git"; in {
      st = "status";
      wlog = "log --color-words";
      wdiff = "diff --color-words";
      wshow = "show --color-words";
      signoff-rebase = "!GIT_SEQUENCE_EDITOR='sed -i -re s/^pick/e/' sh -c '${git} rebase -i $1 && while ${git} rebase --continue; do ${git} commit --amend --signoff --no-edit; done' -";
      prune-merged-branches = "!${git} branch --merged $1 | grep -v \"^\* $1 \" | xargs -n 1 -r git branch -d";
      prune-local-branches = "!${git} branch -vv | grep ': gone]' | grep -v '\\*' | awk '{ print $1; }' | xargs -r ${git} branch -d";
    };

    delta = {
      enable = true;
      options.syntax-theme = "base16-256";
    };

    ignores = [ ".direnv" ];

    extraConfig = {
      core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
      github.user = "otavio";
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
