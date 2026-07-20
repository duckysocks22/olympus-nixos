{ util, pkgs, lib, ... }:
{
  systemd.services.mc-statech-industries = util.functions.mkSimpleService {
    description = "Minecraft Statech Industries Server";
    ExecStart = pkgs.writeShellScript "start.sh" ''
      cd /home/server/game-servers/minecraft/statech-industries
      ${pkgs.jdk17}/bin/java -server -Xmx6G -jar fabric-server-mc.1.19.2-loader.0.16.9-launcher.1.0.1.jar nogui
    '';
    user = "server";
  };
}
