{ inputs, self, ... }:
{
  flake.nixosModules.homepage =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = 8085;
        allowedHosts = "dash.olympus.moe,192.168.10.253:8085,localhost:8085,127.0.0.1:8085";
        environmentFiles = [
          "${config.sops.secrets."homepage/secrets".path}"
        ];

        settings = {
          title = "Olympus Network";
          description = "Dashboard for 'Olympus' HomeLab";
          theme = "dark";

          layout = {
            "Media" = {
              style = "row";
              columns = 4;
            };
          };

          headerStyle = "underlined";
        };

        widgets = [
          {
            resources = {
              cpu = true;
              disk = "/media/hdd1";
              memory = true;
            };
          }
          {
            search = {
              provider = "duckduckgo";
              target = "_blank";
            };
          }
        ];

        services = [
          {
            "Tools" = [
              {
                "ActualBudget" = {
                  description = "Self-Hosted budgeting service. | Requires mTLS";
                  icon = "actual-budget.png";
                  href = "https://budget.olympus.moe";
                  ping = "http://localhost:5006";
                };
              }
            ];
          }
          {
            "Media" = [
              {
                "Jellyfin" = {
                  description = "Self-Hosted Streaming Service";
                  icon = "jellyfin.png";
                  href = "https://stream.puppygirls.net";
                  siteMonitor = "http://localhost:8096";
                };
              }
              {
                "Seerr" = {
                  description = "Movie and TV-Show request service.";
                  icon = "jellyfin.png";
                  href = "https://seerr.puppygirls.net";
                  siteMonitor = "http://localhost:5055";
                };
              }
              {
                "Immich" = {
                  description = "Self-Hosted Image Service | Requires mTLS";
                  icon = "immich.png";
                  href = "https://immich.olympus.moe";
                  ping = "http://localhost:2283";
                };
              }
              {
                "Navidrome" = {
                  description = "Self-Hosted Music Streaming Service";
                  icon = "navidrome.png";
                  href = "https://music.puppygirls.net";
                  siteMonitor = "http://localhost:4533";
                };
              }
              {
                "Audio Bookshelf" = {
                  description = "Self-Hosted Audiobook Service";
                  icon = "audiobookshelf.png";
                  href = "https://audio.puppygirls.net";
                  siteMonitor = "http://localhost:8000";
                };
              }
              {
                "FreshRSS" = {
                  description = "Self-Hosted RSS Feed. | Requires mTLS";
                  icon = "freshrss.png";
                  href = "https://rss.olympus.moe";
                  ping = "http://localhost:8082";
                };
              }
            ];
          }
          {
            "Services" = [
              {
                "DNS" = {
                  description = "Self Hosted AdGuard DNS";
                  icon = "adguard-home.png";
                  ping = "http://localhost:854";
                  widget = {
                    type = "adguard";
                    url = "http://localhost:3003";
                    username = "foxtrot";
                    password = "$ADGUARD_PASS";
                  };
                };
              }
              {
                "Nix Cache" = {
                  description = "Self Hosted NixOS binary cache";
                  icon = "nixos.png";
                  siteMonitor = "http://localhost:7989";
                };
              }
              {
                "Ntfy" = {
                  description = "Ntfy Notification Service";
                  icon = "ntfy.png";
                  ping = "http://localhost:1147";
                };
              }
              {
                "Mollysocket" = {
                  description = "Mollysocket Notification Daemon";
                  icon = "https://avatars.githubusercontent.com/u/58849401?s=60&v=4";
                  ping = "http://localhost:8020";
                };
              }
              {
                "RSSHub" = {
                  description = "RSS Hub Service";
                  icon = "rsshub.png";
                  siteMonitor = "http://localhost:1200";
                };
              }
              {
                "Llama-CPP" = {
                  description = "llama.cpp Instance";
                  icon = "https://avatars.githubusercontent.com/u/134263123?s=60&v=4";
                  ping = "http://localhost:5387";
                };
              }
            ];
          }
          {
            "Game Servers" = [
              {
                "Factorio" = {
                  description = "Factorio";
                  icon = "https://cdn2.steamgriddb.com/icon/6ca4e9af5ea662a095c3243dc591bf54/32/256x256.png";
                  href = "https://factory.puppygirls.net";
                  ping = "http://localhost:42702";
                };
              }
              {
                "Vanilla | Minecraft" = {
                  description = "forever.puppygirls.net";
                  icon = "minecraft.png";
                  widget = {
                    type = "minecraft";
                    url = "udp://localhost:25865";
                  };
                };
              }
              {
                "NTNH | Minecraft" = {
                  description = "statech.puppygirls.net";
                  icon = "https://avatars.githubusercontent.com/u/209024689?s=200&v=4";
                  widget = {
                    type = "minecraft";
                    url = "udp://localhost:25665";
                  };
                };
              }
            ];
          }
          {
            "Admin Tools" = [
              {
                "qBittorrent" = {
                  description = "qBittorrent Instance | Requires mTLS";
                  icon = "qbittorrent.png";
                  href = "https://qbit.olympus.moe";
                  ping = "http://localhost:8080";
                };
              }
              {
                "Home Assistant" = {
                  description = "Home Assistant | Requires mTLS";
                  icon = "home-assistant.png";
                  href = "https://home.olympus.moe";
                  ping = "http://localhost:8123";
                };
              }
              {
                "Copyparty" = {
                  description = "Copyparty Instance | Requires mTLS";
                  icon = "copyparty.png";
                  href = "https://copy.olympus.moe";
                  ping = "http://localhost:3120";
                };
              }
              {
                "Radarr" = {
                  description = "Movie Fetching Service";
                  icon = "radarr.png";
                  href = "https://radarr.puppygirls.net";
                  siteMonitor = "http://localhost:5056";
                };
              }
              {
                "Sonarr" = {
                  description = "Show Fetching Service";
                  icon = "sonarr.png";
                  href = "https://sonarr.puppygirls.net";
                  siteMonitor = "http://localhost:5057";
                };
              }
              {
                "Prowlarr" = {
                  description = "Index Provider Service";
                  icon = "prowlarr.png";
                  href = "https://prowlarr.puppygirls.net";
                  siteMonitor = "http://localhost:5058";
                };
              }

            ];
          }
        ];
      };
    };
}
