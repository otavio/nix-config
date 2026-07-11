{ pkgs, ... }:
{
  home.file = {
    ".gitaliases".source = ./aliases;
  };

  home.packages = with pkgs; [
    git-review
    git-secret
    gitRepo
  ];

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    # Off because it emits gh's store path; the helper is set by bare command
    # in programs.git.settings (see the note there).
    gitCredentialHelper.enable = false;
  };

  programs.git = {
    enable = true;

    signing.format = null;

    # Everything here is referenced by bare command name, never a
    # `${pkgs.*}/bin` store path: the `repo` tool caches this config and never
    # refreshes it (home-manager renders it into a store file whose mtime is
    # frozen at the epoch), so a pinned path breaks once GC removes the
    # superseded generation. Bare names resolve via PATH to the live generation.
    settings = {
      user = {
        name = "Otavio Salvador";
        email = "otavio@ossystems.com.br";
      };

      aliases = let git = "git"; in {
        st = "status";
        wlog = "log --color-words";
        wdiff = "diff --color-words";
        wshow = "show --color-words";
        signoff-rebase = "!GIT_SEQUENCE_EDITOR='sed -i -re s/^pick/e/' sh -c '${git} rebase -i $1 && while ${git} rebase --continue; do ${git} commit --amend --signoff --no-edit; done' -";
        prune-merged-branches = "!${git} branch --merged $1 | grep -v \"^\* $1 \" | xargs -n 1 -r git branch -d";
        prune-local-branches = "!${git} branch -vv | grep ': gone]' | grep -v '\\*' | awk '{ print $1; }' | xargs -r ${git} branch -d";
      };

      core.sshCommand = "ssh -F ~/.ssh/config";

      credential =
        let helper = [ "" "gh auth git-credential" ]; in {
          "https://github.com".helper = helper;
          "https://gist.github.com".helper = helper;
        };

      pager = {
        blame = "delta";
        diff = "delta";
        log = "delta";
        show = "delta";
      };
      interactive.diffFilter = "delta --color-only";
      delta.syntax-theme = "base16-256";

      github.user = "otavio";

      pull = {
        rebase = true;
      };

      sendemail = {
        aliasesfile = "~/.gitaliases";
        aliasfiletype = "mutt";
      };

      rebase = {
        autoStash = true;
        autoSquash = true;
        abbreviateCommands = true;
        missingCommitsCheck = "warn";
      };
    };

    ignores = [ ".direnv" ];
  };

  # Integration left off because it emits delta's store path; delta is wired
  # into git by bare command in settings above (see the note there).
  programs.delta.enable = true;
}
