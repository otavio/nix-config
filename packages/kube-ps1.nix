{ lib, pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "kube-ps1";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-ps1";
    tag = "v${version}";
    sha256 = "sha256-A71FJ5o4lVa6HuSZaFIjVtjXTXN/tnS7gLkWk+A+T70=";
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
