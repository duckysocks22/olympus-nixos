{ inputs, self, ... }:
{
  flake.homeModules.social =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        signal-desktop
      ];
    };
}
