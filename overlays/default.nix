_:

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

    linuxPackages_latest = prev.linuxPackages_latest.extend (_: prev: {
      rtl88x2bu = prev.callPackage ./rtl88x2bu { };
    });
  };
}
