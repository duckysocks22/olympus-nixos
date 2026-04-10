{ pkgs, ... }:

pkgs.buildNpmPackage (self: {
  pname = "puppygirls";
  version = "0.1.0";
  src = ./.;
  npmDepsHash = "sha256-iXovAm85d0VsON2DidB9XPnz4HTI1sLUPJ0K2VSeyaM=";

  buildPhase = ''
    npm run build
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';

  dontNpmInstall = true;
})
