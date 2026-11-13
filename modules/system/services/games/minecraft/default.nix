{ inputs, ... }:
{
  flake.nixosModules.minecraft =
    {
      config,
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

      cfg = config.server.minecraft;
    in
    {
      options = {
        server.minecraft = mkOption {
          type = types.submodule {
            options = {
              enable = mkEnableOption "minecraft";

              servers = mkOption {
                type = types.submodule { };
              };
            };
          };
        };
      };

      config = mkMerge [
        (mkIf (cfg.enable) {
          users.users.minecraft = {
            isSystemUser = true;
            group = "minecraft";
          };

          users.groups.minecraft = { };

          systemd.tmpfiles.rules = [
            "d /home/server/game-servers/minecraft 0600 minecraft minecraft"
          ];
        })
      ];
    };
}
