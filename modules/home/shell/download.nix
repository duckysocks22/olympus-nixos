{ inputs, self, ... }:
{
  flake.homeModules.download =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        aria2
      ];
    };
}
