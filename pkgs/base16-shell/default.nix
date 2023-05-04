{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "base16-shell";
  src = fetchFromGitHub {
    owner = "base16-project";
    repo = "base16-shell";
    rev = "41848241532fd60cdda222cc8f7b2bbead9fb50d";
    sha256 = "sha256-rkgH8J6RgI3ej04z4gPFHMabaBRZKeaXIHhk0HxXMHo=";
  };

  installPhase = ''
    mkdir -p $out/share/base16-shell
    cp -r * $out/share/base16-shell/
  '';
}
