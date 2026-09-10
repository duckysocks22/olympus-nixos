{ inputs, self, ... }: {
  flake.nixosModules.files = { inputs, ... }: {
    imports = [
      self.nixosModules.syncthing
      self.nixosModules.samba
      self.nixosModules.actual-budget
      self.nixosModules.immich
    ];
  };

  flake.nixosModules.immich =
    {
      config,
      lib,
      pkgs-unstable,
      ...
    }:
    {
      services.immich = {
        enable = true;
        package = pkgs-unstable.immich;
        host = "127.0.0.1";
        port = 2283;
        openFirewall = true;
        environment.IMMICH_LOG_LEVEL = "warn";

        accelerationDevices = [ "/dev/dri/renderD128" ];

        settings = {
          backup = {
            database = {
              enabled = true;
              cronExpression = "0 02 * * *";
              keepLastAmount = 14;
            };
          };
          machineLearning = {
            enabled = true;
            urls = [ "http://localhost:3004" ];
            ocr = {
              enabled = true;
              minDetectionScore = 0.5;
              minRecognitionScore = 0.8;
            };
            facialRecognition = {
              enabled = true;
              maxDistance = 0.5;
              minFaces = 3;
              minScore = 0.7;
            };
          };
          map = {
            enabled = true;
            darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
            lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
          };
          nightlyTasks = {
            clusterNewFaces = true;
            databaseCleanup = true;
            generateMemories = true;
            missingThumbnails = true;
            startTime = "04:00";
            syncQuotaUsage = true;
          };
        };

        machine-learning = {
          enable = true;
          environment = {
            IMMICH_PORT = lib.mkForce "3004";
            MACHINE_LEARNING_CACHE_FOLDER = lib.mkForce "/media/hdd1/media/immich/machine-learning/cache";
            MACHINE_LEARNING_WORKERS = lib.mkForce "2";
          };
        };

        redis = {
          enable = true;
        };

        mediaLocation = "/media/hdd1/media/immich/";
        secretsFile = "${config.sops.secrets."immich/secrets".path}";
      };
    };

  flake.nixosModules.actual-budget =
    {
      pkgs,
      util,
      lib,
      ...
    }:
    let
      config = pkgs.writeText "actual-config.json" (
        builtins.toJSON {
          hostname = "0.0.0.0";
          dataDir = "/media/hdd1/services/actual-finance/";
        }
      );
      exec = lib.getExe pkgs.actual-server;
    in
    {
      systemd.services.actual-server = util.functions.mkSimpleService {
        description = "Headless Actual Finance Server";
        ExecStart = "${exec} --config ${config}";
        user = "root";
      };
    };

  flake.nixosModules.syncthing = { config, ... }: {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      key = "${config.sops.secrets."syncthing/nyx/cert".path}";
      cert = "${config.sops.secrets."syncthing/nyx/key".path}";
      settings = {
        gui.user = "foxtrot";
        guiPasswordFile = "${config.sops.secrets."admin/pass".path}";

        folders = {

        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 8384 ];
  };

  flake.nixosModules.samba = { config, pkgs, ... }: {
    services = {
      samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "nyxsmb";
            "netbios name" = "nyxsmb";
            "security" = "user";
            "hosts allow" = "172.17.0.0/16";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "share";
            "map to guest" = "bad user";
            "obey pam restrictions" = "no";
            "inherit permissions" = "yes";
            "inherit acls" = "yes";
          };
          "shared" = {
            "path" = "/media/hdd1/shares/shared";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0664";
            "directory mask" = "0775";
            "force create mode" = "0664";
            "force directory mode" = "0775";
            "force user" = "share";
            "force group" = "users";
          };
          "private" = {
            "path" = "/media/hdd1/shares/private";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "create mask" = "0755";
            "directory mask" = "0755";
            "valid users" = "socks";
          };
        };
      };

      samba-wsdd = {
        enable = true;
        openFirewall = true;
      };
    };

    users = {
      users = {
        socks = {
          description = "Write-access to samba media shares";
          group = "socks";
          extraGroups = [ "users" ];
          hashedPasswordFile = config.sops.secrets."users/server".path;
          isSystemUser = true;
        };
        serena = {
          description = "Write-access to samba media shares";
          group = "serena";
          extraGroups = [ "users" ];
          hashedPasswordFile = config.sops.secrets."users/server".path;
          isSystemUser = true;
        };
        zia = {
          description = "Write-access to samba media shares";
          group = "zia";
          extraGroups = [ "users" ];
          hashedPasswordFile = config.sops.secrets."users/server".path;
          isSystemUser = true;
        };
      };
      groups = {
        socks = { };
        serena = { };
        zia = { };
      };
    };

    system.activationScripts = {
      init_smbpasswdSocks.text = ''
        /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/socks".path
        })\n$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/socks".path
        })\n" | /run/current-system/sw/bin/smbpasswd -sa socks
      '';
      init_smbpasswdSerena.text = ''
        /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/serena".path
        })\n$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/serena".path
        })\n" | /run/current-system/sw/bin/smbpasswd -sa serena
      '';
      init_smbpasswdZia.text = ''
        /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/zia".path
        })\n$(/run/current-system/sw/bin/cat ${
          config.sops.secrets."samba-nyx/zia".path
        })\n" | /run/current-system/sw/bin/smbpasswd -sa zia
      '';
    };
  };
}
