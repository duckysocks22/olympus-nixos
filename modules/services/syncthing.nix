{ inputs, self, ... }:
{
  flake.nixosModules.syncthing =
    {
      config,
      ...
    }:
    let
      address = {
        "nyx-nixos" = "192.168.10.253";
      };

      hostSecrets = ../../secrets/${config.networking.hostName}.yaml;
    in
    {
      services.syncthing = {
        enable = true;
        overrideFolders = true;
        openDefaultPorts = true;

        cert = config.sops.secrets."syncthing/${config.networking.hostName}/cert".path;
        key = config.sops.secrets."syncthing/${config.networking.hostName}/key".path;

        settings = {
          devices = {
            circe-nixos = {
              id = "ECLW26H-2JWNNZX-YUWT42U-CYNARNX-SJRMMXA-XA2I7KD-ATCMTX2-4JXJNAP";
            };
            athena-nixos = {
              id = "JKIY2Y5-V62NP54-PUGNOIZ-N3VQ4QY-7LJ4T4T-WEQWEDX-B7RIP74-J24IGQM";
            };
            dionysus-nixos = {
              id = "AQSHDSY-3I6HO7B-XJTWCSU-5MBSCSL-AU4BWKN-PQUDFE2-YVBZT6R-25G7RAI";
            };
            ariadne-nixos = {
              id = "Z6NPUDI-PZ46LWD-6WJ2AN4-TFTS3ST-VSR4TBS-JSU73RB-MYOPXP7-2ISDWAR";
            };
            nyx-nixos = {
              id = "T5XG4ZF-FYS5II7-JJH5274-CZF2CDG-QDDTASR-FZH7FCO-TQA6UV2-KDFTYQB";
            };
          };
          folders = {
            "FFXIV" = {
              id = "FFXIV";
              path = "/media/hdd1/services/syncthing/ffxiv";
              devices = [
                "circe-nixos"
                "nyx-nixos"
                "dionysus-nixos"
                "athena-nixos"
                "ariadne-nixos"
              ];
              versioning = {
                type = "simple";
                params.keep = "10";
              };
              rescanIntervalS = 60;
              ignorePatterns = [
                "ffxivConfig/FFXIV.cfg"
                "ffxivConfig/FFXIV.cfg.old"
                "pluginConfigs/LightlessSync/tracelog"
                "!.stignore"
                "!accounts.json"
                "!secrets.json"
                "!cfgcopy"
                "!ffxivConfig"
                "!pluginConfigs"
                "!installedPlugins"
                "!dalamudConfig.json"
                "!dalamudUI.ini"
                "!launcherUI.ini"
                "!FFXIV_CHR004000174C7A37AE"
                "*"
              ];
            };
          };
        };
        # wildcard bind, listens whenever the overlay IP exists
        guiAddress = "0.0.0.0:8384";
        guiPasswordFile = "${config.sops.secrets."syncthing/pass".path}";

        settings.gui.user = "foxtrot";
      };

      systemd.services.syncthing = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
      };

      sops.secrets."syncthing/${config.networking.hostName}/cert" = {
        owner = "syncthing";
        sopsFile = hostSecrets;
      };
      sops.secrets."syncthing/${config.networking.hostName}/key" = {
        owner = "syncthing";
        sopsFile = hostSecrets;
      };
      sops.secrets."syncthing/pass" = {
        owner = "syncthing";
        sopsFile = ../../secrets/common.yaml;
      };
    };
}
