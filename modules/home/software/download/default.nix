{ inputs, ... }:
{
  flake.homeModules.download =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        nicotine-plus
      ];
    };
}
