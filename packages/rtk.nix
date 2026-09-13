# nixpkgs is stuck on 0.47.0, whose test suite fails to build. Track the
# current upstream release until the pin catches up, then drop this file in
# favour of nixpkgs' own package. Kept deliberately close to that definition so
# the two stay easy to diff.
{ pkgs, lib }:

pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rtk";
  version = "0.49.0";
  __structuredAttrs = true;

  src = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wlb+yPTsMiZsh3AKzLNM1eFpOvbnLgLb/cCsLG/YrJU=";
  };

  cargoHash = "sha256-cgRtXTd75uKInBnf6dP6e4KHyA2IP9lLEKwVzGq16gg=";

  nativeBuildInputs = with pkgs; [
    makeWrapper
    pkg-config
  ];

  buildInputs = [ pkgs.sqlite ];

  env.LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";

  postInstall = ''
    wrapProgram $out/bin/rtk \
      --prefix PATH : ${lib.makeBinPath [ pkgs.gitMinimal ]}
  '';

  nativeCheckInputs = with pkgs; [
    gitMinimal
    writableTmpDirAsHomeHook
  ];

  # Waits on a shim subprocess that never gets scheduled inside the build
  # sandbox, so it only ever fails on its own 60s timeout. The rest of the
  # suite runs.
  checkFlags = [ "--skip=signalled_run_still_prints_captured_output" ];

  nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "CLI proxy that reduces LLM token consumption by 60-90% on common dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    changelog = "https://github.com/rtk-ai/rtk/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "rtk";
  };
})
