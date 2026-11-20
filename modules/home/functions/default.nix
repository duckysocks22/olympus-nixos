{ inputs, self, ... }:
{
  flake.homeModules.functions = {
    imports = [
      inputs.self.homeModules.mkSimpleService
      inputs.self.homeModules.wrapNoHardened
    ];
  };
}
