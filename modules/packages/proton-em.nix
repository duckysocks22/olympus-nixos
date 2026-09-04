{ inputs, ...}: {

  perSystem = { pkgs, lib, ... }: {
    packages.proton-em = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "proton-em-bin";
      version = "EM-10.0-37-HDR";

      src = pkgs.fetchzip {
        url = "https://github.com/Etaash-mathamsetty/Proton/releases/download/${finalAttrs.version}/proton-${finalAttrs.version}.tar.xz";
        hash = "sha256-yap/7G6TeJ9vMtc5H/iWu8w3sM8mI6762G+K2JzSlgk=";
      };

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      outputs = [
        "out"
        "steamcompattool"
      ];

      installPhase = ''
        runHook preInstall

        # Make it impossible to add to an environment. You should use the appropriate NixOS option.
        # Also leave some breadcrumbs in the file.
        echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

        mkdir $steamcompattool
        ln -s $src/* $steamcompattool
        rm $steamcompattool/compatibilitytool.vdf
        cp $src/compatibilitytool.vdf $steamcompattool

        runHook postInstall
      '';

      preFixup = ''
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
          --replace-fail "${finalAttrs.version}" "proton-EM-10.0-37-HDR"
      '';

      meta = {
        description = ''
          Compatibility tool for Steam Play based on Wine and additional components.

          (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
        '';
        homepage = "https://github.com/Etaash-mathamsetty/Proton";
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    });
  };
}
