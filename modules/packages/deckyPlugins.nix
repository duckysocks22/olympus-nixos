{ inputs, ... }: {

  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        stdenv
        stdenvNoCC
        fetchurl
        unzip
        patchelf
        makeWrapper
        gcc
        libglvnd
        pkgsi686Linux
        ;
      qt6 = pkgs.qt6;
      qtLibs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
      ];
      payloadLibs = [
        gcc.cc.lib
        libglvnd
      ] ++ qtLibs;
    in
    {
      packages.decky-lsfg-vk = stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "decky-lsfg-vk";
        version = "0.14.0";

        src = fetchurl {
          url = "https://github.com/xXJSONDeruloXx/decky-lsfg-vk/releases/download/v${finalAttrs.version}/Decky.LSFG-VK.zip";
          hash = "sha256-KoqsykGNQg0h77RvZaVrdIo9y0Xho1yY0iSxtaTtcDc=";
        };

        nativeBuildInputs = [
          unzip
          patchelf
          makeWrapper
        ];

        dontConfigure = true;
        dontBuild = true;
        dontWrapQtApps = true;

        installPhase = ''
          runHook preInstall
          unzip "$src" -d "$out"

          pluginDir="$out/Decky LSFG-VK"
          payload="$TMP/payload"
          mkdir -p "$payload"
          tar -xJf "$pluginDir/bin/lsfg-vk-2.0.0.tar.xz" -C "$payload"

          rpath64=${lib.makeLibraryPath payloadLibs}

          patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
            --set-rpath "$rpath64" "$payload/bin/lsfg-vk-cli"
          patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
            --set-rpath "$rpath64" "$payload/bin/lsfg-vk-ui"
          patchelf --set-rpath "$rpath64" "$payload/lib/liblsfg-vk-layer.so"
          patchelf --set-rpath "${pkgsi686Linux.gcc.cc.lib}/lib" "$payload/lib/liblsfg-vk-layer.x86.so"

          mv "$payload/bin/lsfg-vk-ui" "$pluginDir/bin/.lsfg-vk-ui-real"
          makeWrapper "$pluginDir/bin/.lsfg-vk-ui-real" "$payload/bin/lsfg-vk-ui" \
            --set QT_PLUGIN_PATH ${lib.makeSearchPath "lib/qt-6/plugins" qtLibs} \
            --set QML_IMPORT_PATH ${lib.makeSearchPath "lib/qt-6/qml" qtLibs} \
            --set QML2_IMPORT_PATH ${lib.makeSearchPath "lib/qt-6/qml" qtLibs}

          tar -cJf "$pluginDir/bin/lsfg-vk-2.0.0.tar.xz" -C "$payload" .

          runHook postInstall
        '';

        meta = {
          description = "Decky Loader plugin enabling Lossless Scaling frame generation via lsfg-vk";
          homepage = "https://github.com/xXJSONDeruloXx/decky-lsfg-vk";
          license = lib.licenses.bsd3;
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
