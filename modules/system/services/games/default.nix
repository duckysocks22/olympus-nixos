{ inputs, ... }:
{
  flake.nixosModules.game-servers =
    {
      ...
    }:
    {
      imports = [
        inputs.self.nixosModules.minecraft
        inputs.self.nixosModules.factorio
      ];

      server.minecraft = {
        enable = true;
        servers = {
          vanilla-forever.enable = true; # Enable Minecraft Vanilla 'Forever World' server
          ntnh.enable = false; # Enable Minecraft "Nuclear Tech: New Horizons"
        };
      };

      server.factorio = {
        ofsm.enable = true; # Enable 'Open Factorio Server Manager'
      };
    };
}
