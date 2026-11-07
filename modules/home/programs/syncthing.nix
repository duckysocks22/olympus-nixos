{ inputs, self, ... }:
{
  flake.homeModules.syncthing =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    let
      address = {
        "circe-nixos" = "192.168.10.2";
        "dionysus-nixos" = "192.168.10.3";
        "ariadne-nixos" = "192.168.10.4";
        "athena-nixos" = "192.168.10.1";
      };

      ffxivIgnorePatterns = [
        "ffxivConfig/FFXIV.cfg"
        "ffxivConfig/FFXIV.cfg.old"
        "pluginConfigs/LightlessSync/tracelog"
        "!dalamudConfig.json"
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
    in
    {
      home.file.".xlcore/.stignore" = {
        text = lib.concatStringsSep "\n" (ffxivIgnorePatterns ++ [ "" ]);
        force = true;
      };
      services.syncthing = {
        enable = true;
        overrideFolders = true;

        cert = config.sops.secrets."syncthing/${osConfig.networking.hostName}/cert".path;
        key = config.sops.secrets."syncthing/${osConfig.networking.hostName}/key".path;

        settings = {
          devices = {
            athena-nixos = {
              id = "JKIY2Y5-V62NP54-PUGNOIZ-N3VQ4QY-7LJ4T4T-WEQWEDX-B7RIP74-J24IGQM";
            };
            circe-nixos = {
              id = "ECLW26H-2JWNNZX-YUWT42U-CYNARNX-SJRMMXA-XA2I7KD-ATCMTX2-4JXJNAP";
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
              path = "${config.home.homeDirectory}/.xlcore";
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
              ignorePatterns = ffxivIgnorePatterns;
            };
          };
        };

        guiAddress = "${address.${osConfig.networking.hostName}}:8384";
        guiCredentials = {
          username = "foxtrot";
          passwordFile = "${config.sops.secrets."syncthing/pass".path}";
        };
      };
    };
}
