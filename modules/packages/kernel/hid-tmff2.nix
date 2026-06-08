{
  stdenv,
  lib,
  fetchFromGitHub,
  kernel,
  kmod,
  ...
}:
stdenv.mkDerivation rec {
  pname = "hid-tmff2";
  version = "0.83";

  src = fetchFromGitHub {
    owner = "Kimplul";
    repo = "hid-tmff2";
    rev = "${version}";
    hash = "sha256-jKmWfBBT3md4kxw49iIwr2yM6Yhr31RLER1Mu/fhBmQ=";
    fetchSubmodules = true;
  };
  
  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installPhase = ''
    runHook preInstall
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd) INSTALL_MOD_PATH=$out modules_install
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd)/deps/hid-tminit INSTALL_MOD_PATH=$out modules_install
    runHook postInstall
  '';

  meta = {
    description = "A kernel module to support Thrustmaster racing wheels";
    homepage = "https://github.com/Kimplul/hid-tmff2";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.duckysocks22 ];
    platforms = lib.platforms.linux;
  };
}
