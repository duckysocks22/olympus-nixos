{ ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.pi-agent-modes = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "pi-agent-modes";
        version = "0.3.0";

        src = pkgs.fetchFromGitHub {
          owner = "yoyo406";
          repo = "pi-agent-modes";
          tag = "v${finalAttrs.version}";
          hash = "sha256-czujF6xEpjQrxPJnrRgSUoE0vO2NI+hHl/gT2eZgmG0=";
        };

        patches = [ ../../patches/pi-agent-modes-0.3.0-ssh.patch ];

        nativeBuildInputs = [ pkgs.nodejs ];

        doCheck = true;
        checkPhase = ''
          runHook preCheck
          node --experimental-strip-types --test tests/*.test.ts
          runHook postCheck
        '';

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
