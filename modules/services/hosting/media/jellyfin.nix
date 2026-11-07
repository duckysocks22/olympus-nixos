{ inputs, self, ... }:
{
  flake.nixosModules.jellyfin =
    {
      inputs,
      pkgs,
      pkgs-unstable,
      ...
    }:
    {
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

  flake.nixosModules.jellyfinExtra =
    {
      inputs,
      config,
      pkgs,
      pkgs-unstable,
      lib,
      ...
    }:
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
      };

      users.groups = {
        seerr = { };
        radarr = { };
        prowlarr = { };
      };

      networking.firewall.allowedTCPPorts = [
        5055
        5056
        5057
        5058
      ];
    };
}
