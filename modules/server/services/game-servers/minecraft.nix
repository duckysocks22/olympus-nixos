{ util, pkgs, lib, ...}:
{
  /* systemd.services.minecraft-statech-industry = util.functions.mkSimpleService {
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
  };*/

  systemd.services.minecraft-atm10 = util.functions.mkSimpleService {
    description = "All The Mods 10 Minecraft Server";
    ExecStart = "${pkgs.writeShellScript "start.sh check" ''
      set -x
      PATH="${lib.makeBinPath [ pkgs.jre ]}:PATH"
      if [ -d /media/hdd1/game-servers/minecraft/atm10/ ]; then
        cd /media/hdd1/game-servers/minecraft/atm10
        java -server -Xms6G -Xmx12G -jar server.jar
      fi
    ''}";
    user = "server";
  };
}
