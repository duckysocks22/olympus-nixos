{ inputs, self, ... }:
{
  flake.nixosModules.thrustmaster =
    {
      ...
    }:
    {
      boot.kernelModules = [
        "hid-tmff-new"
        "hid-tminit-new"
      ];
    };
}
