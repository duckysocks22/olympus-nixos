{ inputs, ... }:
{
  flake.homeModules.development =
    {
      inputs,
      ...
    }:
    {
      imports = [
        inputs.self.homeModules.unity
        inputs.self.homeModules.rider
      ];
    };
}
