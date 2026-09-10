{ inputs, self, ... }: {
  flake.nixosModules.gameServers = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.minecraftServer
      inputs.self.nixosModules.factorioServer
    ];
  };

  flake.nixosModules.minecraftServer =
    {
      pkgs,
      util,
      lib,
      ...
    }:
    {

      systemd.services.mc-statech-industries = util.functions.mkSimpleService {
        description = "Minecraft Statech Industries Server";
        ExecStart = pkgs.writeShellScript "start.sh" ''
          cd /home/server/game-servers/minecraft/statech-industries
          ${pkgs.jdk17}/bin/java -server -Xmx6G -jar fabric-server-mc.1.19.2-loader.0.16.9-launcher.1.0.1.jar nogui
        '';
        user = "server";
      };

      users.users.minecraft = {
        isSystemUser = true;
        group = "minecraft";
      };

      users.groups.minecraft = { };
    };

  flake.nixosModules.factorioServer =
    {
      util,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.services.ofsm = util.functions.mkSimpleService {
        description = "Open Factorio Server Manager";
        ExecStart = "${pkgs.writeShellScript "start.sh check" ''
          set -x
          if [ -d /media/hdd1/game-servers/factorio/ofsm/ ]; then
            cd /media/hdd1/game-servers/factorio/ofsm
            ${pkgs.steam-run}/bin/steam-run ./factorio-server-manager --dir /media/hdd1/game-servers/factorio/game --port "42702"
          fi
        ''}";
        user = "server";
      };
    };
}
