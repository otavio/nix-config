# Named bb-cli rather than bb so the overlay does not shadow nixpkgs' `bb`
# (the unrelated AA-lib demo). The installed binary is still `bb`.
{ pkgs, lib }:

pkgs.buildGoModule (finalAttrs: {
  pname = "bb-cli";
  version = "0.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "craftamap";
    repo = "bb";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hXTMUxNWRsBC8sOdgahhR2+yULSHlt+vnBafMj/g3Jc=";
  };

  vendorHash = "sha256-Q/DmMm5QXRuVakO3RIuwvbbTpU5n39shb4EXL6S8lSQ=";

  nativeBuildInputs = [ pkgs.installShellFiles ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/craftamap/bb/cmd.Version=${finalAttrs.version}"
  ];

  # `bb completion` runs cobra's initializer, which creates the config dir and
  # so panics on the sandbox's unwritable $HOME.
  postInstall = ''
    export HOME="$(mktemp -d)"
    installShellCompletion --cmd bb \
      --bash <($out/bin/bb completion bash) \
      --fish <($out/bin/bb completion fish) \
      --zsh <($out/bin/bb completion zsh)
  '';

  nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  meta = {
    description = "Unofficial Bitbucket.org command line tool";
    homepage = "https://github.com/craftamap/bb";
    changelog = "https://github.com/craftamap/bb/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "bb";
  };
})
