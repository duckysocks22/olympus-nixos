{ pkgs, ...}:
{
  home.packages = with pkgs; [
    vlc
    (symlinkJoin {
      name = "jellyfin-desktop";
      paths = [ jellyfin-desktop ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/jellyfin-desktop \
          --set QT_QPA_PLATFORM "xcb"
      '';
    })
    feishin
  ];
}
