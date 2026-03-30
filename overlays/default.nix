_:

{
  # Auto-discover custom packages from packages/*.nix
  additions = final: _:
    let
      packagesDir = ../packages;
      entries = builtins.readDir packagesDir;
      nixFiles = builtins.filter
        (n: entries.${n} == "regular" && builtins.match ".*\\.nix" n != null)
        (builtins.attrNames entries);
      scope = { pkgs = final; inherit (final) lib; };
      callPkg = path:
        let fn = import path;
        in fn (builtins.intersectAttrs (builtins.functionArgs fn) scope);
    in
    builtins.listToAttrs (builtins.map
      (file:
        let name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
        in {
          inherit name;
          value = callPkg (packagesDir + "/${file}");
        })
      nixFiles);

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
