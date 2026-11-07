{ inputs, self, ... }:
{
  flake.homeModules.direnv =
    {
      config,
      ...
    }:
    {
      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
      };
    };
}
