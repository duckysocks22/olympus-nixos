{ inputs, self, ... }:
{
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

      systemd.services.mc-forever = util.functions.mkSimpleService {
        description = "Minecraft Vanilla";
        ExecStart = pkgs.writeShellScript "start.sh" ''
          cd /home/server/game-servers/minecraft/forever_vanilla

          set -e

          SERVER_JAR="server.jar"

          exec ${pkgs.jdk25}/bin/java -Xms4G -Xmx8G -jar "$SERVER_JAR" nogui

        '';
        user = "server";
      };

      users.users.minecraft = {
        isSystemUser = true;
        group = "minecraft";
      };

      users.groups.minecraft = { };
    };
}
