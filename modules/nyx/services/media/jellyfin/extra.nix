{ pkgs, pkgs-unstable, lib, config, ... }:
{
  services.seerr = {
    enable = true;
    package = pkgs-unstable.seerr;
  };

  services.radarr = {
    enable = true;
    package = pkgs-unstable.radarr;
    settings = {
      server.port = 5056;
    };
  };

  services.sonarr = {
    enable = true;
    package = pkgs-unstable.sonarr;
    settings = {
      server.port = 5057;
    };
  };

  services.prowlarr = {
    enable = true;
    package = pkgs-unstable.prowlarr;
    settings = {
     server.port = 5058;
    };
  };

  services.tdarr = {
    enable = true;
    package = pkgs.tdarr;
    dataDir = "/media/hdd1/services/tdarr";
    user = "tdarr";
    nodes = {
      "nyx" = {
        enable = true;
        name = "nyx";
        dataDir = "/media/hdd1/services/tdarr/nyx";
        environmentFile = "${config.sops.secrets."media/tdarr/node_env".path}";
        package = pkgs.tdarr-node;
        serverURL = "http://127.0.0.1:8266";
        workers = {
          transcodeCPU = 2;
          transcodeGPU = 0;
          healthcheckCPU = 0;
          healthcheckGPU = 4;
        };
      };
    };
    server = {
      auth.enable = true;
      webUIPort = 5059;
      environmentFile = "${config.sops.secrets."media/tdarr/server_env".path}";
    };
  };

  systemd.services.tdarr-node-nyx = {
    serviceConfig = {
      ReadWritePaths = [ 
        "/media/hdd1/services/tdarr/transcode_cache"
        "/media/hdd1/media/jellyfin/library"
      ];
    };
  };

  users.users = {
    seerr = {
      isSystemUser = true;
      group = "seerr";
      extraGroups = [ "jellyfin" "torrent" ];
    };
    radarr = {
      isSystemUser = true;
      group = "radarr";
      extraGroups = [ "jellyfin" "torrent" ];
    };
    sonarr = {
      isSystemUser = true;
      group = "sonarr";
      extraGroups = [ "jellyfin" "torrent" ];
    };
    prowlarr = {
      isSystemUser = true;
      group = "prowlarr";
      extraGroups = [ "jellyfin" "torrent" ];
    };
    tdarr = {
      isSystemUser = true;
      group = "tdarr";
      extraGroups = [ "jellyfin" "torrent" ];
    };
  };

  users.groups = {
    seerr = {};
    radarr = {};
    prowlarr = {};
    tdarr = {};
  };
  
  networking.firewall.allowedTCPPorts = [ 5055 5056 5057 5058 5059 ];
}
