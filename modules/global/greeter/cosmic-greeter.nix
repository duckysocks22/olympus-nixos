{ inputs, ... }:
{
  flake.nixosModules.cosmic-greeter = { ... }: {
    services.displayManager.cosmic-greeter.enable = true;
  };
}
