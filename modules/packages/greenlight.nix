{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  nodejs,
  nspr,
  nss,
  mesa,
  alsa-lib,
  yq,
  unzip,
  electron,
  makeWrapper,
  makeDesktopItem,
  autoPatchelfHook,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "greenlight";
  version = "2.4.1";

  src = fetchFromGitHub {
    owner = "unknownskl";
    repo = "greenlight";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JlhVqw2LsnUZMffngFrI9jr7vzMBaa4vzq+2/+Clzco=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-OvVhxOn3hqWuqaK62fFdbSe3MZhQe4PXllihaLqNOyc=`";
  };

  electronZip = fetchurl {
    url = "https://github.com/electron/electron/releases/download/v38.2.0/electron-v38.2.0-linux-x64.zip";
    hash = "sha256-8AKJdSgqbylGeXF1rEBqlQlvKcXc2pgEgUhmjfo27/g=";
  };

  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [ yarnConfigHook yarnBuildHook yarnInstallHook nodejs yq unzip makeWrapper autoPatchelfHook ];

  buildInputs = [
    nspr
    nss
    mesa
    alsa-lib
    stdenv.cc.cc.lib
  ] ++ electron.buildInputs;

  postPatch = ''
    mkdir -p build/electron-unpacked

    unzip ${finalAttrs.electronZip} -d build/electron-unpacked

    yq -i -y ".electronDist = \"$PWD/build/electron-unpacked\" | 
         del(.linux.target) | 
         .linux.target = [\"dir\"]" $PWD/packages/desktop/electron-builder.yml

  '';

  buildPhase = ''
    runHook preBuild

    yarn --offline desktop build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/greenlight
    mkdir -p $out/bin

    cp -r packages/desktop/dist/linux-unpacked/* $out/lib/greenlight/

    makeWrapper $out/lib/greenlight/greenlight-desktop $out/bin/greenlight \
      --add-flags "--ozone-platform-hint=auto" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs }"

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $out/share/applications
    cp -r ${finalAttrs.desktopItem}/share/applications/* $out/share/applications/

    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp packages/desktop/flatpak/io.github.unknownskl.greenlight.png \
      $out/share/icons/hicolor/512x512/apps/greenlight.png
  '';

  desktopItem = makeDesktopItem {
    name = "greenlight";
    exec = "greenlight %U";
    icon = "${finalAttrs.src}/packages/desktop/flatpak/io.github.unknownskl.greenlight.png";
    desktopName = "Greenlight";
    genericName = "Desktop client for Greenlight-Desktop";
    comment = "${finalAttrs.meta.description}";
    categories = [ "Game" "Utility" ];
    startupWMClass = "Greenlight";
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source client for xCloud and Xbox home streaming made in Typescript";
    homepage = "https://github.com/unknownskl/greenlight";
    downloadPage = "https://github.com/unknownskl/greenlight/releases";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ duckysocks22 ];
    inherit (electron.meta) platforms;
    mainProgram = "greenlight";
  };
})
