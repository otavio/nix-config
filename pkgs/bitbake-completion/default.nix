{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "bitbake-completion";
  src = fetchFromGitHub {
    owner = "lukaszgard";
    repo = "bitbake-completion";
    rev = "95e15443b692ebee60a3260b7018e51d2b7716ce";
    sha256 = "0i3ka8n1y1glx6zws109rkqrwfaxmk4asa085cf0nn5j3ynlss76";
  };

  installPhase = ''
    mkdir -p $out/share/bitbake-completion
    cp -r * $out/share/bitbake-completion/
  '';
}
