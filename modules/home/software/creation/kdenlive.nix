{ inputs, ... }:
{
  flake.homeModules.kdenLive =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        kdePackages.kdenlive
      ];
    };
}
