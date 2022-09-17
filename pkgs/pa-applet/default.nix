{ lib, stdenv, fetchFromGitHub, libpulseaudio, pkg-config, gtk3, glibc, autoconf, automake, libnotify, libX11, xf86inputevdev }:

stdenv.mkDerivation {
  pname = "pa-applet";
  version = "unstable-2021-11-15";

  src = fetchFromGitHub {
    owner = "Deecellar";
    repo = "pa-applet";
    rev = "a60f4651df2dc556b12f6dff9f06c7d6a79fff52";
    sha256 = "sha256-3uRbQWRizp7jp01g+ESEiTyo+yjGEv7n6+LRhsDta88=";
  };

  nativeBuildInputs = [ pkg-config autoconf automake ];
  buildInputs = [
    gtk3
    libpulseaudio
    glibc
    libnotify
    libX11
    xf86inputevdev
  ];

  preConfigure = ''
    ./autogen.sh
  '';

  # work around a problem related to gtk3 updates
  NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";

  postInstall = "";

  meta = with lib; {
    description = "";
    license = licenses.gpl2;
    maintainers = with maintainers; [ domenkozar ];
    platforms = platforms.linux;
  };
}
