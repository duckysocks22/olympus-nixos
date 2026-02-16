{ inputs, pkgs, ...}:
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.minecraft-servers = {
    servers.stoneblock4 = {
      enable = true;
      eula = true;
      openFirewall = true;

      package = pkgs.neoforgeServers.neoforge-1_21_1.override {
        loaderVersion = "21.1.216";
      };

      symLinks = {
        "mods" = /media/hdd1/game-servers/minecraft/stoneblock4/mods;
        "world" = /media/hdd1/game-servers/minecraft/stoneblock4/world;
      };
    };
  };
}
