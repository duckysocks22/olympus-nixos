{ ... }: {

  perSystem = { pkgs, ... }: {
    packages.steamos-plymouth = pkgs.runCommand "steamos-plymouth-theme" { } ''
      mkdir -p $out/share/plymouth/themes/steamos
      cp -r ${pkgs.fetchFromGitHub {
        owner = "arvigeus";
        repo = "plymouth-theme-steamos";
        rev = "2fa02f8497a80f1aad6429dcafc3bcbda760c6c8";
        hash = "sha256-Y01KFbV0AQjKDoAD3/xISxckHRW5k59Sc5CbLZjyfVs=";
      }}/* $out/share/plymouth/themes/steamos/
      substituteInPlace $out/share/plymouth/themes/steamos/steamos.plymouth \
        --replace-fail /usr/share/plymouth/themes $out/share/plymouth/themes
    '';
  };
}
