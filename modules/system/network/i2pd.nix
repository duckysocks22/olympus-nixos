{ inputs, self, ... }:
{
  flake.nixosModules.i2pd =
    {
      config,
      ...
    }:
    {
      services.i2pd = {
        enable = true;

        proto = {
          sam.enable = true;
          socksProxy.enable = true;
          httpProxy.enable = true;
        };
      };
    };
}
