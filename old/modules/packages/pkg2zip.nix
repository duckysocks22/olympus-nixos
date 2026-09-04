{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "pkg2zip";
  version = "v2.6";

  src = fetchFromGitHub {
    owner = "lusid1";
    repo = "pkg2zip";
    rev = "2.6";
    hash = "sha256-zjYKOzttq2vrCwVclCm9EPE0rfJrPaKD0FPVeRT9948=";
  };

  buildInputs = [ ];

  NIX_CFLAGS_COMPILE = "-Wno-error=array-bounds";

  buildPhase = ''
    make
  '';

  installPhase = ''
    make install PREFIX=$out
  '';

  meta = with lib; {
    description = "pkg2zip";
  };
}
