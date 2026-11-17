{ inputs, self, ... }:
{
  flake.nixosModules.functions =
    {
      inputs,
      ...
    }:
    {
      imports = [
        inputs.self.nixosModules.simpleService
      ];
    };
}
