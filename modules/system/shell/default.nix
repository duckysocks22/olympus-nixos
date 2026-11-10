{ inputs, self, ... }:
{
  flake.nixosModules.shell =
    {
      ...
    }:
    {
      programs.fish.enable = true;
    };
}
