{ inputs }:

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

    talon-unwrapped = prev.talon-unwrapped.overrideAttrs (_: {
      version = "0.4.0-1134";
      src = builtins.fetchurl {
        url = inputs.nix-secrets.talon-beta-url;
        sha256 = "sha256:1vbkqdapxdrg7n6fsmxv2j8w0yscsgwz9zqy6nkk22jbwh4zzhb2";
      };
    });

    linuxPackages_latest = prev.linuxPackages_latest.extend (_: prev: {
      rtl88x2bu = prev.callPackage ./rtl88x2bu { };
    });
  };
}
