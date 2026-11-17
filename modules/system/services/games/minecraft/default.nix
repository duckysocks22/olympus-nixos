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
      imports = [
        inputs.self.nixosModules.vanilla-forever
        inputs.self.nixosModules.ntnh
      ];

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
            "z /media/hdd1/game-servers/minecraft 0700 minecraft minecraft"
          ];
        })
      ];
    };
}
