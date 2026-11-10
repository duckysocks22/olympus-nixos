{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.assets = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "assets";
        version = "1.0";
        src = ../assets;

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/assets
          cp -r ./* $out/share/assets
          runHook postInstall
        '';
      });
    };
}
