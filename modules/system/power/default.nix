{ inputs, self, ... }:
{
  flake.nixosModules.power =
    {
      ...
    }:
    {
      services = {
        tuned.enable = true;
        upower.enable = true;
      };
    };
}
