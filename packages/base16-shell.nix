{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "base16-shell";
  src = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-shell";
    rev = "9359c5da5adec80f374a6ef62178ab3e5613c800";
    sha256 = "sha256-4tVnlKGPbiO1Fblmces7IRtvjG7weedJhjYkMBk080Q=";
  };

  installPhase = ''
    mkdir -p $out/share/base16-shell
    cp -r * $out/share/base16-shell/
  '';
}
