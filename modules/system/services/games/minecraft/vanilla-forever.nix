{ inputs, ... }:
{
  flake.nixosModules.vanilla-forever =
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

      cfg = config.server.minecraft.servers.vanilla-forever;
    in
    {
      options = {
        server.minecraft.servers.vanilla-forever = mkEnableOption "vanilla-forver";
      };

      config = mkMerge [
        (mkIf (cfg.enable) {
          systemd.services.mc-forever = util.functions.mkSimpleService {
            description = "Minecraft Vanilla";

            ExecStart = pkgs.writeShellScript "start.sh" ''
              set -e

              cd /home/server/game-servers/minecraft/forever_vanilla

              SERVER_JAR="server.jar"

              exec ${pkgs.jdk25}/bin/java -Xms4G -Xmx8G -jar "$SERVER_JAR" nogui
            '';

            user = "minecraft";
          };
        })
      ];
    };
}
