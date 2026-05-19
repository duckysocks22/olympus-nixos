{
  lib,
  appimageTools,
  fetchurl,
  nix-update-script,
}:
(appimageTools.wrapType2 rec {
  pname = "greenlight";
  version = "2.4.1";

  src = fetchurl {
    url = "https://github.com/unknownskl/greenlight/releases/download/v${version}/Greenlight-${version}.AppImage";
    hash = "sha256-CYf0BCkQB4ms9bj9fPgEgdjHA/JvKaCxgC6wb7/bc1c=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  extraInstallCommands =
    let
      appimageContents = appimageTools.extractType1 { inherit pname src version; };
    in
    ''
      install -D ${appimageContents}/greenlight-desktop.desktop $out/share/applications/greenlight.desktop
      install -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/greenlight-desktop.png $out/share/icons/hicolor/512x512/apps/greenlight.png
      substituteInPlace $out/share/applications/greenlight.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=greenlight' \
        --replace-fail 'Icon=greenlight-desktop' 'Icon=greenlight'
    '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "An open-source client for xCloud and Xbox home streaming made in Typescript.";
    homepage = "https://github.com/unknownskl/greenlight";
    downloadPage = "https://github.com/unknownskl/greenlight/releases";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ duckysocks22 ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "greenlight";
  };
})
// {
  strictDeps = true;
  __structuredAttrs = true;
}
