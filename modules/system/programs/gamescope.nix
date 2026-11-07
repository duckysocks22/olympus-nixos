{ inputs, self, ... }:
{
  flake.nixosModules.gamescope =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.gamescope.enable = true;
    };
}
