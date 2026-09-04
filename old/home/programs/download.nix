{ pkgs, inputs, ... }:
{
  home.packages =
    (with pkgs; [
      nicotine-plus
      qbittorrent
      asunder
      makemkv
    ])
    ++ (with inputs.luxxy-pkgs.packages.${pkgs.stdenv.hostPlatform.system}; [
      (jdownloader.override {
        darkTheme = true;
      })
    ]);
}
