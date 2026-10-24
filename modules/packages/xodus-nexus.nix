{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      pname = "xodus-nexus";
      version = "0.3.11";

      src = pkgs.fetchurl {
        url = "https://github.com/domsvoboda/xodus-nexus/releases/download/v${version}/Xodus-Nexus-${version}-x86_64.AppImage";
        hash = "sha256-r1hpK/5dFTDui8/o7hIGCKLqcZ5FzZN4jk4m9MudvgM=";
      };

      appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    {
      packages.xodus-nexus = pkgs.appimageTools.wrapType2 {
        inherit pname version src;

        # the launcher downloads and execs its own backend and Wine runtime at runtime
        includeClosures = true;

        # the bundled Wine runtime ships i386-unix binaries whose interpreter is
        # /lib/ld-linux.so.2; a 64-bit-only FHS env has no such loader, so a game dies with
        # "/lib/ld-linux.so.2: could not open" (multiArch is what steam/lutris/bottles set)
        multiArch = true;

        # 'Add to Steam' hands the shortcut over by exec'ing the hardcoded /usr/bin/steam,
        # which an FHS env does not have, so the client never receives the URI and the
        # launcher reports that it cannot send to the Steam client. /run is bind-mounted
        # from the host, so the system Steam wrapper is reachable from inside.
        extraBuildCommands = ''
          mkdir -p $out/usr/bin
          ln -sf /run/current-system/sw/bin/steam $out/usr/bin/steam
        '';

        # absolute Exec: the launcher copies it verbatim into 'Add to Steam' shortcuts
        extraInstallCommands = ''
          # Nexus only offers per-game Steam shortcuts when it can name a persistent launcher
          # path. The FHS wrapper exports APPDIR (the extracted AppImage tree) and no
          # APPIMAGE, which makes it disable them, so hand it this wrapper as its launcher.
          mv $out/bin/${pname} $out/bin/${pname}-wrapped
          cat > $out/bin/${pname} <<EOF
          #!/bin/sh
          export APPIMAGE=$out/bin/${pname}
          exec $out/bin/${pname}-wrapped "\$@"
          EOF
          chmod 755 $out/bin/${pname}

          install -Dm444 ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
          install -Dm444 /dev/stdin $out/share/applications/${pname}.desktop <<EOF
          [Desktop Entry]
          Type=Application
          Name=Xodus Nexus
          Comment=Xbox-inspired Microsoft Store game launcher
          Exec=$out/bin/${pname}
          Icon=${pname}
          Categories=Game;
          Terminal=false
          EOF
        '';

        meta = {
          description = "Xbox-inspired Microsoft Store game launcher for Linux";
          homepage = "https://github.com/domsvoboda/xodus-nexus";
          downloadPage = "https://github.com/domsvoboda/xodus-nexus/releases/tag/v${version}";
          license = lib.licenses.mit;
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          mainProgram = pname;
          platforms = [ "x86_64-linux" ];
        };
      };
    };
}
