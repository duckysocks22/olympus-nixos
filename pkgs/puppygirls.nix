{ inputs, ... }: {
  perSystem = { pkgs, lib, ... }: {
    packages.puppygirls = pkgs.buildNpmPackage (self: {
      pname = "puppygirls";
      version = "0.1.0";
      src = "${
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
      }/share/assets/puppygirls-web";
      npmDepsHash = "sha256-Z0zGQUvfPWA7KHwBBMUpwqNWM0YPii5HjMeGXB77Zio=";

      buildPhase = ''
        npm run build
      '';

      installPhase = ''
        mkdir -p $out
        cp -r dist/* $out/
      '';

      dontNpmInstall = true;
    });
  };
}
