{ lib
, stdenv
, fetchFromGitHub
, kernel
, bc
,
}:

stdenv.mkDerivation {
  pname = "rtl88x2bu";
  version = "${kernel.version}-unstable-2024-05-11";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "88x2bu-20210702";
    rev = "e96ef9a9e0a9261598137b3ad2c70fa018914764";
    sha256 = "sha256-Y0nsVIyPHxGEdWXu5iUzNnpJ4lVXsQChV86P/F4c02c=";
  };

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = [ bc ] ++ kernel.moduleBuildDependencies;
  inherit (kernel) makeFlags;

  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/ "${kernel.dev}/lib/modules/" \
      --replace /sbin/depmod \# \
      --replace '$(MODDESTDIR)' "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Realtek rtl88x2bu driver";
    homepage = "https://github.com/morrownr/88x2bu-20210702";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ otavio ];
  };
}
