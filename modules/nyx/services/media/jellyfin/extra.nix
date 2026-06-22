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
    package = pkgs-unstable.tdarr;
    dataDir = "/media/hdd1/services/tdarr";
    user = "tdarr";
    nodes = {
      "nyx" = {
        enable = true;
        name = "nyx";
        dataDir = "/media/hdd1/services/tdarr/nyx";
        environmentFile = "${config.sops.secrets."media/tdarr/node_env".path}";
        package = pkgs-unstable.tdarr-node;
        serverURL = "http://127.0.0.1:8266";
        workers = {
          transcodeCPU = 0;
          transcodeGPU = 1;
          healthcheckCPU = 4;
          healthcheckGPU = 0;
        };
      };
    };
    server = {
      auth.enable = true;
      webUIPort = 5059;
      environmentFile = "${config.sops.secrets."media/tdarr/server_env".path}";
    };
  };

  systemd.tmpfiles.rules = [
    "d /media/hdd1/services/tdarr/transcode_cache 0755 tdarr tdarr -"
  ];

  # Restart tdarr-server every 12 hours to compact its NeDB database and
  # prevent the event-loop freeze that occurs as job reports accumulate.
  # Remove once tdarr migrates to a non-blocking DB backend.
  systemd.services.tdarr-server-restart = {
    description = "Periodic tdarr-server restart (NeDB compaction)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart tdarr-server.service";
    };
  };

  systemd.timers.tdarr-server-restart = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03,15:00:00"; # 3am and 3pm
      Persistent = true;
    };
  };

  systemd.services.tdarr-node-nyx = {
    environment = {
      ffmpegPath = "${pkgs.ffmpeg-tdarr}/bin/ffmpeg";
    };
    serviceConfig = {
      ReadWritePaths = [
        "/media/hdd1/services/tdarr/transcode_cache"
        "/media/hdd1/media/jellyfin/library"
      ];
    };
  };

  systemd.services.sonarr = {
    serviceConfig = {
      Group = lib.mkForce "jellyfin";
    };
  };

  systemd.services.radarr = {
    serviceConfig = {
      Group = lib.mkForce "jellyfin";
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
