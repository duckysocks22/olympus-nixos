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

      systemd.services.mc-ntnh = util.functions.mkSimpleService {
        description = "Minecraft Nuclear Tech New Horizons Server";
        ExecStart = pkgs.writeShellScript "start.sh" ''
          cd /home/server/game-servers/minecraft/ntnh-server

          set -e

          SERVER_JAR="forge-1.7.10-10.13.4.1614-1.7.10-universal.jar"

          exec ${pkgs.jdk8}/bin/java -Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -jar "$SERVER_JAR" nogui

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
