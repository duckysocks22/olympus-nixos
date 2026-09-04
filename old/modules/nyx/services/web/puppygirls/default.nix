{ pkgs, ... }:

pkgs.buildNpmPackage (self: {
  pname = "puppygirls";
  version = "0.1.0";
  src = ./.;
  npmDepsHash = "sha256-Z0zGQUvfPWA7KHwBBMUpwqNWM0YPii5HjMeGXB77Zio=";

  buildPhase = ''
    npm run build
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';

  dontNpmInstall = true;
})
