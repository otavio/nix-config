{ mkDerivation
, lib
, fetchFromGitHub
, qtbase
, cmake
, qttools
, qtsvg
, kguiaddons
, grim
, nix-update-script
}:

mkDerivation {
  pname = "flameshot";
  version = "12.1.0-unstable-2023-11-25";

  src = fetchFromGitHub {
    owner = "flameshot-org";
    repo = "flameshot";
    rev = "3d21e4967b68e9ce80fb2238857aa1bf12c7b905";
    sha256 = "sha256-OLRtF/yjHDN+sIbgilBZ6sBZ3FO6K533kFC1L2peugc=";
  };

  passthru = {
    updateScript = nix-update-script { };
  };

  nativeBuildInputs = [ cmake qttools qtsvg ];
  buildInputs = [ qtbase kguiaddons ];
  cmakeFlags = [
    "-DUSE_WAYLAND_CLIPBOARD=true"
    "-DUSE_WAYLAND_GRIM=true"
  ];

  postInstall = ''
    wrapProgram $out/bin/flameshot \
      --prefix PATH : ${lib.makeBinPath [ grim ]}
  '';

  meta = with lib; {
    description = "Powerful yet simple to use screenshot software";
    homepage = "https://github.com/flameshot-org/flameshot";
    mainProgram = "flameshot";
    maintainers = with maintainers; [ scode oxalica ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
