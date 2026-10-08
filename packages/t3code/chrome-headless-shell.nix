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
  # the t3code build checks it.
  archives = {
    x86_64-linux = {
      platform = "linux64";
      sha256 = "636aa5c79f2693632e9921b8bbb050038ba11672e02346c06c20f991aed096f9";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      sha256 = "0ed0e47d9e9f639197f508d62ada09e5c6b4c4c60edab3160a9312a733091df6";
    };
  };
  archive =
    archives.${stdenv.hostPlatform.system}
      or (throw "chrome-headless-shell: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "chrome-headless-shell";
  version = "154.0.8037.92";

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
