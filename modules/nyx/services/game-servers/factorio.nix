{ util, pkgs, lib, ... }:
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
}
