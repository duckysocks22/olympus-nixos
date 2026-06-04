{
  config,
  lib,
  pkgs,
  ...
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
        Directory where the Piped-Backend will store it's data and execute from.
      '';
    };

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

    database.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enabled the included PostgreSQL Database";
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
        WorkingDirectory = cfg.dataDir;
        ExecStartPre = let
          script = pkgs.writeShellScript "piped-backend-prestart" ''
            mkdir -p "${cfg.dataDir}"
            chown ${cfg.user}:${cfg.group} "${cfg.dataDir}"
            chmod 0750 "${cfg.dataDir}"
            
            cp ${piped-pkg}/share/piped-backend/config.properties "${cfg.dataDir}/config.properties"
            chown ${cfg.user}:${cfg.group} "${cfg.dataDir}/config.properties"
            
            while IFS='=' read -r key value; do
              [[ "$$key" =~ ^#.*$ || -z "$$key" ]] && continue
              sed -i "s|^$$key=.*|$$key=$$value|" "${cfg.dataDir}/config.properties"
              grep -q "^$$key=" "${cfg.dataDir}/config.properties" \
                || echo "$$key=$$value" >> "${cfg.dataDir}/config.properties"
            done < ${generatedConfig}
            
            chmod 0440 "${cfg.dataDir}/config.properties"
          '';
        in "+${script}";
        ExecStart = lib.getExe piped-pkg;
        Restart = "on-failure";
        RestartSec = "10s";
        Type = "simple";
      };
    };
  }) ++ lib.mkIf cfg.database.enable {
    systemd.services.piped-postgresql = {
      description = "Piped-Backend SQL Database";
      wantedBy = [ "piped-backend.service" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = lib.getExe pkgs.postgresql;
        Restart = "on-falure";

        # Hardening from NixOS postgresql module
        CapabilityBoundingSet = [ "" ];
        DevicePolicy = "closed";
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
        LockPersonality = true;
        PrivateDevices = true;
        PrivateMounts = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK" # used for network interface enumeration
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
