{ inputs, self, ... }: {
  flake.nixosModules.serverMedia = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.jellyfin
      inputs.self.nixosModules.navidrome
      inputs.self.nixosModules.freshrss
      inputs.self.nixosModules.audiobookshelf
      inputs.self.nixosModules.qbittorrent
    ];
  };

  flake.nixosModules.qbittorrent = { util, pkgs, lib, ... }: {
    systemd.services.qbittorrent = util.functions.mkSimpleService {
      description = "Headless qBittorrent";
      ExecStart = lib.getExe pkgs.qbittorrent-nox;
      user = "server";
    };

    users.groups.torrent = { };
  };

  flake.nixosModules.audiobookshelf = { pkgs-unstable, ... }: {
    services.audiobookshelf = {
      enable = true;
      package = pkgs-unstable.audiobookshelf;
      openFirewall = true;
      user = "server";
      host = "0.0.0.0";
    };
  };

  flake.nixosModules.freshrss = { config, ... }: {
    services.freshrss = {
      enable = true;
      api.enable = true;
      webserver = "nginx";
      virtualHost = "freshrss";
      baseUrl = "https://rss.olympus.moe";
      defaultUser = "foxtrot";
      authType = "form";
      passwordFile = config.sops.secrets."media/freshrss".path;
    };

    services.nginx.virtualHosts."freshrss" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 8082;
          ssl = false;
        }
      ];
    };

    services.rsshub = {
      enable = true;
      settings = {
        LISTEN_INADDR_ANY = true;
        PORT = 1200;
      };
      redis.enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 1200 ];
  };

  flake.nixosModules.navidrome = { lib, config, ... }: {
    services.navidrome = {
      enable = true;
      environmentFile = "${config.sops.secrets."navidrome/environment".path}";
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "/media/hdd1/audio/music";
        AutoImportPlaylists = false;
        EnableSharing = true;
        openFirewall = true;
        AutoTranscodeDownload = true;
        Agents = "lastfm,deezer,listenbrains";
        LastFM.Enabled = true;
      };
    };
    systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";
  };

  flake.nixosModules.jellyfin = { inputs, pkgs, pkgs-unstable, ... }: {
    environment.systemPackages = with pkgs; [
      jellyfin-web
      jellyfin-ffmpeg
    ];

    disabledModules = [
      "services/misc/jellyfin.nix"
    ];

    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/jellyfin.nix"
      inputs.self.nixosModules.jellyfinExtra
    ];

    services.jellyfin = {
      enable = true;
      package = pkgs-unstable.jellyfin;
      openFirewall = true;
      dataDir = "/media/hdd1/media/jellyfin/media";
      configDir = "/media/hdd1/media/jellyfin/config";
      cacheDir = "/media/hdd1/media/jellyfin/cache";
      logDir = "/media/hdd1/media/jellyfin/logs";
      user = "server";
      forceEncodingConfig = true;
      transcoding = {
        enableHardwareEncoding = true;
        enableToneMapping = true;
        deleteSegments = true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          hevc10bit = true;
        };
      };
      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/dri/renderD128";
      };
    };

    systemd.services.jellyfin.serviceConfig = {
      DeviceAllow = [
        "/dev/nvidiactl rw"
        "/dev/nvidia0 rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
      PrivateDevices = false;
    };

    users.users.jellyfin = {
      isSystemUser = true;
      group = "jellyfin";
    };

    users.groups.jellyfin = { };
  };

  flake.nixosModules.jellyfinExtra = { inputs, config, pkgs, pkgs-unstable, lib, ... }: {
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
      enable = false;
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
      wantedBy = [ ];
      timerConfig = {
        OnCalendar = "*-*-* 03,15:00:00"; # 3am and 3pm
        Persistent = true;
      };
    };

    systemd.services.tdarr-node-nyx = {
      enable = false;
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
        extraGroups = [
          "jellyfin"
          "torrent"
        ];
      };
      radarr = {
        isSystemUser = true;
        group = "radarr";
        extraGroups = [
          "jellyfin"
          "torrent"
        ];
      };
      sonarr = {
        isSystemUser = true;
        group = "sonarr";
        extraGroups = [
          "jellyfin"
          "torrent"
        ];
      };
      prowlarr = {
        isSystemUser = true;
        group = "prowlarr";
        extraGroups = [
          "jellyfin"
          "torrent"
        ];
      };
      tdarr = {
        isSystemUser = true;
        group = "tdarr";
        extraGroups = [
          "jellyfin"
          "torrent"
        ];
      };
    };

    users.groups = {
      seerr = { };
      radarr = { };
      prowlarr = { };
      tdarr = { };
    };

    networking.firewall.allowedTCPPorts = [
      5055
      5056
      5057
      5058
      5059
    ];
  };
}
