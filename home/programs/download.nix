{ inputs, ... }:
{
  flake.homeModules.download = { pkgs, inputs, ... }: {
    home.packages = (with pkgs; [
      nicotine-plus
      qbittorrent
      asunder
      makemkv
    ]) ++ (with inputs.luxxy-pkgs.packages.${pkgs.system}; [
      (jdownloader.override {
        darkTheme = true;
      })
    ]);
  };
}
