{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle,
  makeWrapper,
  formats,
  jre,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "piped-backend";
  version = "6d0ad06";

  src = fetchFromGitHub {
    owner = "TeamPiped";
    repo = "Piped-Backend";
    rev = "${finalAttrs.version}";
    hash = "sha256-d8lkmZmARLgIJX88sWh5KS+ntxx2iBx15zB1sbC4OIA=";
  };

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleFlags = [ "-Dfile.encoding=utf-8" ];

  gradleBuildTask = "shadowJar";

  doCheck = true;

  installPhase = ''
    mkdir -p $out/{bin,share/piped-backend}
    cp build/libs/piped-1.0-all.jar $out/share/piped-backend/
    cp config.properties $out/share/piped-backend/

    makeWrapper ${lib.getExe jre} $out/bin/piped-backend \
      --add-flags "-jar $out/share/piped-backend/piped-1.0-all.jar"
  '';

  meta = {
    description = "";
    homepage = "";
    downloadPage = "";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ duckysocks22 ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes ; [
      fromSource
      binaryBytecode
    ];
  };
})
