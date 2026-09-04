{ inputs, ... }:

perSystem = { lib, appimageTools, fetchurl, }: let
  version = "1.9.2";
  pname = "moondeck-buddy";

  src = fetchurl {
    url = "https://github.com/FrogTheFrog/moondeck-buddy/releases/download/v${version}/MoonDeckBuddy-${version}-x86_64.AppImage";
    hash = "sha256-SfaqrBJJZlJwhSPLPUlwfzZ8RxIWrbwY6uys8ziRvek=";
  };
  in {
  packages.moondeckbuddy = appimageTools.wrapType2 rec {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/MoonDeckBuddy.desktop $out/share/applications/${pname}.desktop
      install -m 444 -D ${appimageContents}/moondeckbuddy.png $out/share/icons/hicolor/64x64/apps/moondeckbuddy.png
      substituteInPlace $out/share/applications/${pname}.desktop \
        -replace-fail 'Exec=MoonDeckBuddy' 'Exec=${meta.mainProgram}'
    '';

    meta = {
      description = "Server-side part of the 'MoonDeck' plugin for Decky Loader";
      homepage = "https://github.com/FrogTheFrog/moondeck-buddy";
      downloadPage = "https://github.com/FrogTheFrog/moondeck-buddy/releases/tag/v1.9.2";
      license = lib.licenses.mit;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "moondeck-buddy";
      maintainers = with lib.maintainers; [ duckysocks22 ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
