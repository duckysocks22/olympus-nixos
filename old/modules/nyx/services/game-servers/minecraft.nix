{
  util,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  /*
    systemd.services.minecraft-statech-industry = util.functions.mkSimpleService {
        description = "Statech Industry Minecraft Server";
        ExecStart = "${pkgs.writeShellScript "start.sh check" ''
          set -x
          PATH="${lib.makeBinPath [ pkgs.jre ]}:PATH"
          if [ -d /media/hdd1/game-servers/minecraft/statech_industry/ ]; then
            cd /media/hdd1/game-servers/minecraft/statech_industry
            java -server -Xmx8G -jar fabric-server-mc.1.19.2-loader.0.16.9-launcher.1.0.1.jar nogui
          fi
        ''}";
        user = "server";
    };
  */

  systemd.services.minecraft-atm10 = util.functions.mkSimpleService {
    description = "All The Mods 10 Minecraft Server";
    ExecStart = "${pkgs.writeShellScript "start.sh check" ''
      set -x
      PATH="${lib.makeBinPath [ pkgs.jre ]}:PATH"
      if [ -d /home/server/game-servers/minecraft/atm10/ ]; then
        cd /home/server/game-servers/minecraft/atm10
        java -server -Xms6G -Xmx10G -jar server.jar
      fi
    ''}";
    user = "server";
  };

  systemd.services.minecraft-gtnh = util.functions.mkSimpleService {
    description = "GregTech New Horizons";
    ExecStart = "${pkgs.writeShellScript "start.sh check" ''
      set -x
      PATH="${lib.makeBinPath [ pkgs.jre ]}:PATH"
      if [ -d /home/server/game-servers/minecraft/gtnh/ ]; then
        cd /home/server/game-servers/minecraft/gtnh
        java -Xms6G -Xmx6G -Dfml.readTimeout=180 @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui
      fi
    ''}";
  };

  systemd.services.minecraft-forever = util.functions.mkSimpleService {
    description = "PuppyGirls Forever,,,,";
    ExecStart = "${pkgs.writeShellScript "start.sh check" ''
      set -x
      PATH="${lib.makeBinPath [ pkgs.openjdk25 ]}:PATH"
      if [ -d /home/server/game-servers/minecraft/forever_vanilla/ ]; then
        cd /home/server/game-servers/minecraft/forever_vanilla
        export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.systemd ]}
        java -server -Xms4G -Xmx6G --enable-native-access=ALL-UNNAMED -jar server.jar
      fi
    ''}";
    user = "server";
  };
}
