{ inputs, self, ... }:
{
  flake.homeModules.ranger =
    {
      config,
      ...
    }:
    {
      programs.ranger.enable = true;
    };
}
