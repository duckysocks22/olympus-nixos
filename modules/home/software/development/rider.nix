{ inputs, ... }:
{
  flake.homeModules.rider =
    {
      pkgs,
      lib,
      ...
    }:
    let
      extra-path = with pkgs; [
        # Core
        dotnetCorePackages.sdk_9_0
        dotnetPackages.Nuget
        mono
        msbuild

        # Additional

      ];

      extra-lib = with pkgs; [
        # Additional Libraries
      ];

      rider = pkgs.jetbrains.rider.overrideAttrs (attrs: {
        postInstall = ''
          # Wrap rider with extra tools and libraries
          mv $out/bin/rider $out/bin/.rider-toolless

          makeWrapper $out/bin/.rider-toolless $out/bin/rider \
            --argv0 rider \
            --prefix PATH : "${lib.makeBinPath extra-path}" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"

          # Enable use of Unity Rider plugin.
          shopt -s extglob
          ln -s $out/rider/!(bin) $out/
          shopt -u extglob
        ''
        + attrs.postInstall or "";
      });
    in
    {
      home.packages = [ rider ];

      home.file.".local/share/applications/jetbrains-rider.desktop".source =
        let
          desktopFile = pkgs.makeDesktopItem {
            name = "jetbrains-rider";
            desktopName = "Rider";
            exec = "\"${rider}/bin/rider\"";
            icon = "rider";
            type = "Application";

            # Don't show desktop icon in search or run launcher
            extraConfig.NoDisplay = "true";
          };
        in
        "${desktopFile}/share/applications/jetbrains-rider.desktop";
    };
}
