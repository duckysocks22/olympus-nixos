{ inputs, ... }: {

  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        stdenv
        stdenvNoCC
        fetchurl
        unzip
        xz
        patchelf
        gcc
        libglvnd
        pkgsi686Linux
        ;
      qt6 = pkgs.qt6;
      payloadLibs = [
        gcc.cc.lib
        libglvnd
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
      ];
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
          xz
          patchelf
        ];
        buildInputs = payloadLibs ++ [ pkgsi686Linux.gcc.cc.lib ];

        dontConfigure = true;
        dontBuild = true;
        dontWrapQtApps = true;

        installPhase = ''
          runHook preInstall
          unzip "$src" -d "$out"

          payloadDir=$TMP/payload
          mkdir -p "$payloadDir"
          tar -xJf "$out/Decky LSFG-VK/bin/lsfg-vk-2.0.0.tar.xz" -C "$payloadDir"


          rpath64=${lib.makeLibraryPath payloadLibs}
          rpath32=${pkgsi686Linux.gcc.cc.lib}/lib

          patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
            --set-rpath "$rpath64" "$payloadDir/bin/lsfg-vk-cli"
          patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
            --set-rpath "$rpath64" "$payloadDir/bin/lsfg-vk-ui"
          patchelf --set-rpath "$rpath64" "$payloadDir/lib/liblsfg-vk-layer.so"
          patchelf --set-rpath "$rpath32" "$payloadDir/lib/liblsfg-vk-layer.x86.so"

          tar -cJf "$out/Decky LSFG-VK/bin/lsfg-vk-2.0.0.tar.xz" -C "$payloadDir" .

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
