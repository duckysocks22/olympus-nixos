{ inputs, ... }: {

  perSystem = { pkgs, lib, ... }: {
    packages.xlm = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "xlm";
      version = "0.4.0";

      src = pkgs.fetchurl {
        url = "https://github.com/Blooym/xlm/releases/download/v${finalAttrs.version}/xlm-x86_64-unknown-linux-gnu";
        hash = "sha256-uDn2M7WuTOplNG5RoNidXCz26T4/wfRt510+MIFihpE=";
      };

      nativeBuildInputs = [ pkgs.patchelf ];

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      outputs = [
        "out"
        "steamcompattool"
      ];

      installPhase = ''
        runHook preInstall

        echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

        install -m755 $src xlm
        patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
          --set-rpath "${lib.makeLibraryPath [
            pkgs.glibc
            pkgs.stdenv.cc.cc.lib
          ]}" xlm

        mkdir compat
        ./xlm install-steam-tool --xlm-updater-disable \
          --extra-launch-args="--xlm-updater-disable --run-as-steam-compat-tool=true --use-fallback-secret-provider" \
          --steam-compat-path "$PWD/compat"

        mkdir -p $steamcompattool
        mv compat/XLM/* $steamcompattool/

        substituteInPlace "$steamcompattool/xlm.sh" \
          --replace-fail '$tooldir/xlcore' '$HOME/.local/share/xlcore'

        runHook postInstall
      '';

      meta = {
        description = ''
          XIVLauncher compatibility tool for Steam (XLCore [XLM]).

          (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
        '';
        homepage = "https://github.com/Blooym/xlm";
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    });
  };
}
