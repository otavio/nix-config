{ python311
, fetchFromGitHub
, gitFull
, git
}:

python311.pkgs.buildPythonApplication rec {
  pname = "patman";
  version = "2021.10";

  src = fetchFromGitHub {
    repo = "u-boot";
    owner = "u-boot";
    rev = "v${version}";
    sha256 = "sha256-2CcIHGbm0HPmY63Xsjaf/Yy78JbRPNhmvZmRJAyla2U=";
  };

  patches = ./patman-expand-user-home-when-looking-for-the-alias-f.patch;

  sourceRoot = "source/tools/patman";

  makeWrapperArgs = [ "--prefix PATH : ${gitFull}/bin" ];

  buildInputs = [ git ];

  postInstall = ''
    cp README $out/bin
  '';

  doCheck = false;
}
