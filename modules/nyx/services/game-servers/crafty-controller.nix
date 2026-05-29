{ ... }:
{
  imports = [ ../../../packages/crafty-controller/crafty-service.nix ];

  services.crafty-controller = {
    enable = true;
    dataDir = "/media/hdd1/game-servers/crafty";
    settings = {
      
    };
  };
}
