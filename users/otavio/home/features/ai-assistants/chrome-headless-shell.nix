# The Chrome for Testing headless shell that T3's browser tabs and HTML render
# previews run. T3 downloads it into ~/.t3/tools on first use, where it cannot
# load its libraries on NixOS; this is the same pinned archive with its
# libraries patched in, for home-manager to put in that place instead.
{
  lib,
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  dbus,
  expat,
  fetchurl,
  glib,
  libgbm,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  stdenv,
  systemdLibs,
  unzip,
}:

let
  # Must match VERSION and ARCHIVES in apps/server/src/preview/PreviewBrowser.ts;
  # update it with each t3code bump.
  archives = {
    x86_64-linux = {
      platform = "linux64";
      sha256 = "a313da592261ff1e342c1e507d315f25b1809006c0508f77ce86151d464d4ccb";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      sha256 = "dca11213d2e0b1db52141edd9f92ec423fd52ca25715846790d84fa1d5d16e8a";
    };
  };
  archive =
    archives.${stdenv.hostPlatform.system}
      or (throw "chrome-headless-shell: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "chrome-headless-shell";
  version = "156.0.8078.70";

  src = fetchurl {
    url = "https://storage.googleapis.com/chrome-for-testing-public/${finalAttrs.version}/${archive.platform}/chrome-headless-shell-${archive.platform}.zip";
    inherit (archive) sha256;
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    dbus
    expat
    glib
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    systemdLibs
  ];

  installPhase = ''
    runHook preInstall
    cp -R . $out
    runHook postInstall
  '';

  passthru = {
    inherit (archive) platform;
    inherit archives;
  };

  meta = {
    description = "Chrome for Testing headless shell pinned by T3 Code";
    homepage = "https://googlechromelabs.github.io/chrome-for-testing/";
    license = lib.licenses.bsd3;
    platforms = lib.attrNames archives;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
