{ lib, pkgs, ... }:

pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "dotagents";
  version = "3.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "getsentry";
    repo = "dotagents";
    tag = finalAttrs.version;
    hash = "sha256-EnVCH0tKCUEcKu+CvkOgc3y9QM0k3rPeJbJ6qcfXVhI=";
  };

  pnpmWorkspaces = [ "@sentry/dotagents..." ];

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      pnpmWorkspaces
      src
      version
      ;
    pnpm = pkgs.pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-XLzTLiOQH2qWoPmT892rwDNTkN6+xftiXOTre0efGM4=";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.nodejs
    pkgs.pnpmConfigHook
    pkgs.pnpm_10
  ];

  env.CI = true;

  buildPhase = ''
    runHook preBuild
    pnpm --filter "@sentry/dotagents..." build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    rm -rf node_modules packages/*/node_modules
    pnpm install --offline --prod --filter "@sentry/dotagents..."
    mkdir -p $out/lib/dotagents/packages
    cp -r node_modules $out/lib/dotagents/
    for pkg in dotagents dotagents-lib; do
      mkdir -p $out/lib/dotagents/packages/$pkg
      cp -r packages/$pkg/{package.json,dist,node_modules} $out/lib/dotagents/packages/$pkg/
    done
    find $out -xtype l -delete
    makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/dotagents \
      --add-flags $out/lib/dotagents/packages/dotagents/dist/cli/index.js \
      --prefix PATH : ${lib.makeBinPath [ pkgs.git ]}
    runHook postInstall
  '';

  meta = {
    description = "Package manager for .agents directories";
    homepage = "https://github.com/getsentry/dotagents";
    changelog = "https://github.com/getsentry/dotagents/blob/${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "dotagents";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ otavio ];
  };
})
