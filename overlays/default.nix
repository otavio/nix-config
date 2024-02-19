{
  # Adds my custom packages
  additions = final: _: import ../pkgs { pkgs = final; };

  modifications = _: prev: {
    fzf = prev.fzf.overrideAttrs (oa: {
      # https://github.com/NixOS/nixpkgs/pull/226847
      postInstall = oa.postInstall + ''
        substituteInPlace $out/share/fzf/completion.* $out/share/fzf/key-bindings.* \
          --replace "\"fzf\"" "\"$out/bin/fzf\"" \
          --replace "fzf-tmux " "$out/bin/fzf-tmux " \
          --replace "fzf " "$out/bin/fzf "
      '';
    });

    tmux = prev.tmux.overrideAttrs (oa: {
      # https://github.com/NixOS/nixpkgs/pull/289789
      patches = (oa.patches or [ ]) ++ [
        (prev.fetchpatch {
          url = "https://github.com/tmux/tmux/commit/2d1afa0e62a24aa7c53ce4fb6f1e35e29d01a904.diff";
          hash = "sha256-mDt5wy570qrUc0clGa3GhZFTKgL0sfnQcWJEJBKAbKs=";
        })
      ];
    });
  };
}
