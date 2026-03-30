{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "kube-ps1";
  version = "0.7.0+git";

  src = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-ps1";
    rev = "db95d30d8f154ac6677a3232745d0326f29d72c4";
    sha256 = "sha256-2UrUOslk60pl15DPS5KwolX/xp3TpWLZKuF2D7jup2o=";
  };

  strictDeps = true;
  buildInputs = [ pkgs.bash ];
  installPhase = ''
    install -D kube-ps1.sh --target-directory=$out/share/kube-ps1
  '';

  meta = with lib; {
    description = "Kubernetes prompt for bash and zsh";
    inherit (src.meta) homepage;
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = with maintainers; [ otavio ];
  };
}
