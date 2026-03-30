{ pkgs, lib, ... }:

let
  # red-tape's pkgs doesn't have allowUnfree, so reimport when needed
  pkgs' =
    if pkgs.config.allowUnfree or false then pkgs
    else
      import pkgs.path {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

  runTalon = pkgs'.writeShellScript "talon-run" ''
    unset QT_AUTO_SCREEN_SCALE_FACTOR QT_SCALE_FACTOR
    export LC_NUMERIC=C
    export QT_PLUGIN_PATH="/lib/plugins"
    export LD_LIBRARY_PATH="$HOME/.talon-bin/resources/python/lib/python3.11/site-packages/numpy.libs:$HOME/.talon-bin/resources/python/lib:$HOME/.talon-bin/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$HOME/.talon-bin/talon" "$@"
  '';
in
pkgs'.buildFHSEnv {
  name = "talon";

  targetPkgs = _: with pkgs'; [
    stdenv.cc.cc
    stdenv.cc.libc
    dbus
    fontconfig
    freetype
    glib
    libGL
    libxkbcommon
    sqlite
    zlib
    libpulseaudio
    udev
    libx11
    libsm
    libxcursor
    libice
    libxrender
    libxcb
    libxext
    libxcomposite
    libxrandr
    libxi
    bzip2
    ncurses5
    libuuid
    gtk3-x11
    gdk-pixbuf
    cairo
    libdrm
    pango
    gdbm
    atk
    wayland
    wayland-protocols
    wlroots
    xwayland
    libinput
    libxml2
    speechd
    gfortran
    (lib.getLib gfortran.cc)
  ];

  runScript = runTalon;

  meta = {
    homepage = "https://talonvoice.com/";
    description = "FHS wrapper for manually-installed Talon voice coding";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
