final: prev:
{
  # PR sent - https://github.com/NixOS/nixpkgs/pull/170276
  python3 = prev.python3.override {
    packageOverrides = final: prev: {
      libtmux = final.callPackage ./libtmux { };
    };
  };

  tmuxp = prev.callPackage ./tmuxp { };
  python3Packages = final.python3.pkgs;
} // (import ../pkgs) { pkgs = final; }
