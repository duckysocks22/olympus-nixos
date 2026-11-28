{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
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
    in
    {
      packages.decky-helixsrmanager = stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "Decky-HelixSRManager";
        version = "0.13.1";

        src = fetchurl {
          url = "";
          hash = lib.fakeHash;
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
          mkdir -p "$out"
          unzip -q "$src" -d "$out"
          runHook postInstall
        '';
      });
    };
}
