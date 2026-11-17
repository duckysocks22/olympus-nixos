{ inputs, self, ... }:
{
  flake.nixosModules.bluetooth =
    {
      ...
    }:
    {
      hardware.bluetooth = {
        enable = true;
        settings = {
          General = {
            FastConnectable = true;
          };

          Policy = {
            AutoEnable = false;
          };
        };
      };
    };
}
