{ pkgs, inputs, ...}:
{
  home.packages = (with pkgs; [
    nicotine-plus
    qbittorrent
  ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.system}; [
    (jdownloader.override {
      darkTheme = true;
    })
  ]);
}
