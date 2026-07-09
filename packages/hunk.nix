{ pkgs, lib, ... }:

# Hunk ships only as prebuilt per-platform binaries on npm; hunkdiff-linux-x64
# is a bun single-file executable (the bun runtime with the app appended after
# the ELF). autoPatchelfHook/strip rewrite the ELF and corrupt that trailing
# payload, after which bun can't find its embedded app and degrades to the bare
# bun CLI (`hunk diff` -> `Script not found "diff"`). So leave the binary
# byte-for-byte intact and run it through the dynamic loader via a wrapper.
# Bump version and hash together from https://registry.npmjs.org/hunkdiff-linux-x64.
pkgs.stdenv.mkDerivation rec {
  pname = "hunk";
  version = "0.17.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/hunkdiff-linux-x64/-/hunkdiff-linux-x64-${version}.tgz";
    hash = "sha256-Q15Hs5eVg7Hg+dQYBnzOw6zpDWneSNZXsTkS9YvZpOM=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/hunk "$out/libexec/hunk"
    makeWrapper ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$out/bin/hunk" \
      --add-flags "--library-path ${lib.makeLibraryPath [ pkgs.glibc ]} $out/libexec/hunk"
    runHook postInstall
  '';

  meta = {
    description = "Desktop-inspired terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ otavio ];
  };
}
