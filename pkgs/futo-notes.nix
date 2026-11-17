{ inputs, ... }:
{
  perSystem =
    {
      self',
      system,
      lib,
      ...
    }:
    {
      packages.futo-notes =
        let
          pkgs = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfreePredicate = p: lib.getName p == "futo-notes";
          };
        in
        pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = "futo-notes";
          version = "1.9.2";
          src = pkgs.fetchFromGitHub {
            owner = "futo-org";
            repo = "futo-notes";
            tag = "v${finalAttrs.version}";
            hash = "sha256-2+3pOefK0BWVunI8QSI1M/3V9161tEjJ+xGXXytE0ko=";
          };

          cargoHash = "sha256-LO690k1AESP7DfGyxWebop9WTSmqhQvvCmyyquqIc3s=";

          nativeBuildInputs = with pkgs; [
            cargo-tauri.hook
            pkg-config
            nodejs
            pnpm_10
            pnpmConfigHook
            wrapGAppsHook3
          ];

          buildInputs = with pkgs; [
            gtk3
            webkitgtk_4_1
            librsvg
            libayatana-appindicator
            openssl
          ];

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = pkgs.pnpm_10;
            fetcherVersion = 3;
            hash = "sha256-+YlrI/rfYah+PZLDU0KRvHZTwZ8o/76WiK6ZD9NqcB8=";
          };

          buildAndTestSubdir = "apps/tauri";
          tauriBundleType = "deb";
          doCheck = false;

          meta = {
            description = "FUTO Open-source Notes App";
            mainProgram = "futo-notes-tauri";
            homepage = "https://notes.futo.tech/";
            platforms = [ "x86_64-linux" ];
            license = lib.licenses.sfl;
          };
        });

      packages.futo-notes-server =
        let
          pkgs = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfreePredicate = p: lib.getName p == "futo-notes-server";
          };
        in
        pkgs.buildGo127Module (finalAttrs: {
          pname = "futo-notes-server";
          version = "0.7.1";
          src = pkgs.fetchFromGitHub {
            owner = "futo-org";
            repo = "futo-notes-server";
            tag = "v${finalAttrs.version}";
            hash = "sha256-RtJjqrr1Vi7GluaRvHldKPBHn19nmikRwkrlRmMb5e0=";
          };

          vendorHash = "sha256-QDr4K2yoTV1yVWOT2EiajQHIdldSJRBzSuJaVU1ndBI=";
          ldflags = [
            "-s"
            "-w"
            "-X"
            "main.serverVersion=${finalAttrs.version}"
          ];

          meta = {
            description = "Server backend for FUTO Notes livesync";
            mainProgram = "server";
            homepage = "https://notes.futo.tech/";
            platforms = [ "x86_64-linux" ];
            license = lib.licenses.sfl;
          };
        });
    };
}
