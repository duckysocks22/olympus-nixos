{ inputs, ... }:
{
  flake.nixosModules.ntnh =
    {
      config,
      pkgs,
      util,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkEnableOption
        mkMerge
        types
        ;

      cfg = config.server.minecraft.servers.ntnh;
    in
    {
      options = {
        server.minecraft.servers.ntnh = mkEnableOption "ntnh";
      };

      config = mkMerge [
        (mkIf (cfg.enable) {
          systemd.services.mc-ntnh = util.functions.mkSimpleService {
            description = "Minecraft Nuclear Tech New Horizons Server";
            ExecStart = pkgs.writeShellScript "start.sh" ''
              set -e

              cd /home/server/game-servers/minecraft/ntnh-server

              SERVER_JAR="forge-1.7.10-10.13.4.1614-1.7.10-universal.jar"

              exec ${pkgs.jdk8}/bin/java -Xms4G -Xmx8G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -jar "$SERVER_JAR" nogui

            '';

            user = "minecraft";
          };
        })
      ];
    };
}
