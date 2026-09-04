{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.crafty-controller;
  crafty-pkg = pkgs.callPackage ./crafty-pkg.nix { };
  format = pkgs.formats.json { };
in
{
  options.services.crafty-controller = {
    enable = lib.mkEnableOption "Crafty Controller Minecraft server management panel";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/crafty-controller";
      description = ''
        Directory where Crafty stores its application code, server files, config,
        and logs. Override this to place data on a separate volume.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "crafty";
      description = "User account Crafty Controller runs under.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "crafty";
      description = "Group Crafty Controller runs under.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open TCP port 8443 in the firewall for the Crafty web interface.";
    };

    mutableConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling this allows any imperative changes made through Crafty's WebUI to stick after service restart.";
    };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      example = lib.literalExpression ''
        {
          https_port = 8443;
          base_url = "mc.example.com:8443";
          language = "en_EN";
          cookie_expire = 30;
          max_login_attempts = 5;
          superMFA = true;
          crafty_logs_delete_after_days = 14;
        }
      '';
      description = ''
        Configuration for the Crafty Controller service to be written to
        '$dataDir/app/config/config.json' on service startup.

        Any non-set values will be set to Crafty's upstream defaults. These 
        values will be merged with Craft's built-in `MASTER_CONFIG` on service startup.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      generatedConfig = format.generate "config.json" cfg.settings;
    in
    {
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
      };

      users.groups.${cfg.group} = { };

      # Create the data directory before the service starts.
      # The wrapper's install/upgrade logic requires it to be writable by cfg.user.
      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      ];

      systemd.services.crafty-controller = {
        description = "Crafty Controller Minecraft server management panel";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        # The wrapper script honours $CRAFTY_HOME when set, falling back to
        # $HOME/.local/share/crafty-controller for manual invocations.
        environment.CRAFTY_HOME = cfg.dataDir;
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStartPre =
            let
              script = pkgs.writeShellScript "crafty-prestart" ''
                set -eu
                # NOTE: this script runs as root (see the leading '+' on the
                # ExecStartPre line below). That is what lets us bootstrap
                # cfg.dataDir even when it lives outside /var on a mount whose
                # parent is not writable by cfg.user — the systemd.tmpfiles rule
                # is best-effort at boot and is not reliable across switch-time
                # and mount-ordering edge cases.
                mkdir -p "${cfg.dataDir}/app/config"
                chown ${cfg.user}:${cfg.group} \
                  "${cfg.dataDir}" \
                  "${cfg.dataDir}/app" \
                  "${cfg.dataDir}/app/config"
                chmod 0750 "${cfg.dataDir}" "${cfg.dataDir}/app" "${cfg.dataDir}/app/config"
                ${
                  if cfg.mutableConfig then
                    ''
                      if [ ! -e "${cfg.dataDir}/app/config/config.json" ]; then
                        install -o ${cfg.user} -g ${cfg.group} -m 0640 \
                          ${generatedConfig} "${cfg.dataDir}/app/config/config.json"
                      fi
                    ''
                  else
                    ''
                      install -o ${cfg.user} -g ${cfg.group} -m 0640 \
                        ${generatedConfig} "${cfg.dataDir}/app/config/config.json"
                    ''
                }
              '';
            in
            "+${script}";
          # --daemon skips crafty's interactive cmd.Cmd loop. Without this flag,
          # cmdloop() calls input() on stdin, which is /dev/null, which raises
          # EOFError every iteration; cmd.Cmd converts that to the string "EOF",
          # no command matches, default() prints "*** Unknown syntax: EOF", and
          # the loop spins at full speed flooding the journal.
          ExecStart = "${lib.getExe crafty-pkg} --daemon";
          Restart = "on-failure";
          RestartSec = "10s";
          Type = "simple";
          StandardInput = "null";
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 8443 ];
    }
  );
}
