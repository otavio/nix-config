{ lib
, stdenv
, fetchFromGitLab
, cmake
, extra-cmake-modules
, pkg-config
, qt6Packages
, kdePackages

, libxcb
}:

stdenv.mkDerivation {
  pname = "xwaylandvideobridge";
  version = "0.4.0+git-1a8d5af993260596ac6e711eb91b3f0ae465cf5d";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "system";
    repo = "xwaylandvideobridge";
    rev = "1a8d5af993260596ac6e711eb91b3f0ae465cf5d";
    hash = "sha256-v3VJC9hLMAb6HMFDbDqgOc1oWVhXf3xudWaABr4JZGQ=";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = [
    qt6Packages.qtbase
    qt6Packages.qtdeclarative
    kdePackages.kcoreaddons
    kdePackages.ki18n
    kdePackages.kwindowsystem
    kdePackages.knotifications
    kdePackages.kcrash
    kdePackages.kstatusnotifieritem
    kdePackages.kpipewire
    libxcb
  ];

  cmakeFlags = [
    "-DQT_MAJOR_VERSION=6"
  ];

  meta = {
    description = "Utility to allow streaming Wayland windows to X applications";
    homepage = "https://invent.kde.org/system/xwaylandvideobridge";
    license = with lib.licenses; [ bsd3 cc0 gpl2Plus ];
    maintainers = with lib.maintainers; [ stepbrobd ];
    platforms = lib.platforms.linux;
    mainProgram = "xwaylandvideobridge";
  };
}
