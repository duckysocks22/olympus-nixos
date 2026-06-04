{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.services.piped-backend;
  piped-pkg = pkgs.callPackage ./default.nix {};
  format = pkgs.formats.json {};
in
{
  options.services.piped-backend = {
    enable = lib.mkEnableOption "Piped-Backend API";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/piped-backend";
      description = ''
        Directory where the Piped-Backend will store it's data.
      '';

      user = lib.mkOption {
        type = lib.types.str;
        default = "piped";
        description = "User account Piped-Backend runs under.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "piped";
        description = "Group Piped-Backend runs under.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open TCP port for Piped-Backend instance.";
      };

      settings = lib.mkOption {
        type = format.type;
        default = {};
        example = lib.literalExpression ''
          {
            
          }
        '';
        description = ''
          Configuration for the Piped-Backend instance to be written to '$dataDir' on service startup.

          Any non-set values will be set to Piped-Backend's upstream defaults. These values will be
          merged with Piped's built-in configuration on service startup.
        '';
      };
    };

    config = lib.mkIf cfg.enable (let
      generatedConfig = format.generate "config.properties" cfg.settings;
    in {
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
      };

      users.groups.${cfg.group} = {};

      systemd.services.piped-backend = {
        description = "Piped-Backend API";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStartPre = let
            script = pkgs.writeShellScript "piped-backend-prestart" ''
              install -o ${cfg.user} -g ${cfg.group} -m 0440 \
                ${generatedConfig} "${cfg.dataDir}/config.properties"
            '';
          in "+${script}";
          ExecStart = lib.getExe piped-pkg;
          Restart = "on-failure";
          RestartSec = "10s";
          Type = "simple";
        };
      };
    });
  };
}
