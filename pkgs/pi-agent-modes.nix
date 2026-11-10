{ ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.pi-agent-modes = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "pi-agent-modes";
        version = "0.3.0";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/pi-agent-modes/-/pi-agent-modes-${finalAttrs.version}.tgz";
          hash = "sha256-+xJ6e9j6E5Oma1drbF54PnqAnB2wRv6rWH2eNegNj7E=";
        };

        unpackPhase = ''
          runHook preUnpack
          tar xzf $src
          runHook postUnpack
        '';
        sourceRoot = "package";

        patches = [ ../patches/pi-agent-modes-0.3.0-ssh.patch ];

        nativeBuildInputs = [ pkgs.nodejs ];

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -r . "$out"/
          runHook postInstall
        '';

        meta = {
          description = "Switchable workflow modes for pi with ssh-capable read-only shell validation";
          homepage = "https://github.com/yoyo406/pi-agent-modes";
          license = lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
