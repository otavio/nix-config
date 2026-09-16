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
    # Python 3.14's configparser rejects keys containing the delimiter, and
    # timekpr 0.5.8 writes its commented config template through it, so the
    # daemon dies initialising per-user config. Upstream dropped configparser
    # in 0.5.9; drop this once the nixpkgs pin carries 0.5.10.
    timekpr = prev.timekpr.override { python3Packages = prev.python312Packages; };
  };
}
