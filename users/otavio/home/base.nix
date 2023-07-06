{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Local scripts added to default PATH.
    (pkgs.stdenv.mkDerivation {
      name = "base-scripts";
      src = ./scripts;
      installPhase = ''
        mkdir -p $out/bin
        cp -r * $out/bin
      '';
    })

    gping
    htop
    mtr
    nnn
    tree
    xclip

    axel
    wget
    nettools # for ifconfig
    psmisc # for killall

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR
  ];
}
