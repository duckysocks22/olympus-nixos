{ inputs, ... }:
{
  flake.nixosModules.factorio =
    {
      config,
      util,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkOption
        mkMerge
        mkEnableOption
        types
        ;

      cfg = config.server.factorio;
    in
    {
      options = {
        server.factorio = mkOption {
          type = types.submodule {
            options = {
              ofsm = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkEnableOption "ofsm";
                  };
                };
              };
            };
          };
        };
      };

      config = mkMerge [
        (mkIf (cfg.ofsm.enable) {
          systemd.services.ofsm = util.functions.mkSimpleService {
            description = "Open Factorio Server Manager";

            ExecStart = "${pkgs.writeShellScript "start.sh check" ''
              set -x
              if [ -d /media/hdd1/game-servers/factorio/ofsm/ ]; then
                cd /media/hdd1/game-servers/factorio/ofsm
                ${pkgs.steam-run}/bin/steam-run ./factorio-server-manager --dir /media/hdd1/game-servers/factorio/game --port "42702"
              fi
            ''}";

            user = "factorio";
          };

          users.users.factorio = {
            isSystemUser = true;
            group = "factorio";
          };

          users.groups.factorio = { };

          systemd.tmpfiles.rules = [
            "d /media/hdd1/game-servers/factorio 0600 factorio factorio"
          ];
        })
      ];
    };
}
