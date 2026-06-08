{ pkgs, lib, ... }:

let
  pkgs' =
    if pkgs.config.allowUnfree or false then pkgs
    else
      import pkgs.path {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

  pname = "superset";
  version = "1.12.4";

  src = pkgs'.fetchurl {
    url = "https://github.com/superset-sh/superset/releases/download/desktop-v${version}/Superset-x86_64.AppImage";
    hash = "sha256-dOCE2dPoSSR+gtCzOa9yfvRXTv4kV1w3G1Hb/0l+PvA=";
  };

  appimageContents = pkgs'.appimageTools.extractType2 { inherit pname version src; };

  electron = pkgs'.electron_40;
in
pkgs'.stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = with pkgs'; [ autoPatchelfHook ];

  buildInputs = with pkgs'; [
    stdenv.cc.cc.lib
    libx11
    libxkbcommon
    libxkbfile
    systemd
    zlib
  ];

  # Manual patchelf on bundled modules only; patching electron strips its RPATH.
  dontAutoPatchelf = true;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    appDir=$out/libexec/${pname}
    wrapped=$out/libexec/${pname}-wrapped

    mkdir -p $out/bin $appDir

    # Rename: Electron sets app.isPackaged=false when execPath basename is 'electron'.
    for f in ${electron.unwrapped}/libexec/electron/*; do
      base=$(basename "$f")
      case "$base" in
        electron) cp "$f" $appDir/${pname} ;;
        resources) ;;
        *) ln -s "$f" $appDir/$base ;;
      esac
    done

    cp -r ${appimageContents}/resources $appDir/
    chmod -R u+w $appDir/resources

    appUnp=$appDir/resources/app.asar.unpacked/node_modules
    rm -rf $appUnp/{bufferutil,node-pty,utf-8-validate}/prebuilds/{darwin,win32}-*
    rm -rf $appUnp/@ast-grep/napi-linux-x64-musl
    rm -rf $appUnp/@libsql/linux-x64-musl
    rm -rf $appUnp/@parcel/watcher-linux-x64-musl
    find $appUnp -name '*.musl.node' -delete
    find $appUnp/koffi/build/koffi -mindepth 1 -maxdepth 1 -not -name linux_x64 -exec rm -rf {} +

    substitute ${electron}/bin/electron $wrapped \
      --replace-fail "${electron.unwrapped}/libexec/electron/electron" "$appDir/${pname}"
    chmod +x $wrapped

    # Login shell so spawned subprocesses inherit user PATH. Use the user's
    # actual shell so zsh-only env files (~/.zshenv) are sourced; bash -l
    # would miss them.
    cat > $out/bin/${pname} <<EOF
    #!${pkgs'.bashInteractive}/bin/bash
    shell="\''${SHELL:-${pkgs'.zsh}/bin/zsh}"
    # i3 hands us a stale SSH_AUTH_SOCK captured at X-session start
    # (typically gnome-keyring's), so the var is set but the socket may
    # not be live. Keychain files (refreshed by \`keys-load\`) win when present.
    if [ -z "\$SSH_AUTH_SOCK" ] || [ ! -S "\$SSH_AUTH_SOCK" ]; then
      _hn=\$(hostname)
      if [ -f "\$HOME/.keychain/\$_hn-sh" ]; then
        . "\$HOME/.keychain/\$_hn-sh"
        [ -f "\$HOME/.keychain/\$_hn-sh-gpg" ] && . "\$HOME/.keychain/\$_hn-sh-gpg"
      elif command -v systemctl >/dev/null 2>&1; then
        eval "\$(systemctl --user show-environment 2>/dev/null | sed -n 's/^\(SSH_AUTH_SOCK\|SSH_AGENT_PID\)=/export \1=/p')"
      fi
      unset _hn
    fi
    # Contain runaway memory inside a transient user scope so a ballooning
    # renderer/agent gets OOM-killed locally instead of taking down the host
    # (peak observed in the wild: ~41G RSS + 17G swap).
    exec ${pkgs'.systemd}/bin/systemd-run --user --scope --quiet --collect \\
      -p MemoryHigh=24G -p MemoryMax=32G -p MemorySwapMax=4G \\
      -- "\$shell" -l -c 'exec $wrapped "\$@"' "\$shell" "\$@"
    EOF
    chmod +x $out/bin/${pname}

    install -Dm444 ${appimageContents}/@supersetdesktop.desktop \
      $out/share/applications/${pname}.desktop
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}' \
      --replace-fail 'Icon=@supersetdesktop' 'Icon=${pname}'

    for size in 16 32 48 64 128 256 512 1024; do
      install -Dm444 \
        ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/@supersetdesktop.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
    done

    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf $out/libexec/${pname}/resources/app.asar.unpacked
  '';

  passthru.updateScript = pkgs'.writeShellApplication {
    name = "update-${pname}";
    runtimeInputs = with pkgs'; [ curl jq nix-update ];
    text = ''
      latest=$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/repos/superset-sh/superset/releases/latest \
        | jq -r '.tag_name' \
        | sed 's/^desktop-v//')
      exec nix-update --flake --version "$latest" ${pname}
    '';
  };

  meta = {
    description = "Desktop code editor for running an army of AI coding agents (Claude Code, Codex, etc.)";
    homepage = "https://superset.sh";
    license = lib.licenses.elastic20;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ otavio ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
