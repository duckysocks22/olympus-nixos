{ inputs, self, ... }: {
  flake.nixosModules.servicesNetwork = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.netbirdServer
    ];
  };

  flake.nixosModules.netbirdServer =
    {
      config,
      pkgs-unstable,
      lib,
      ...
    }:
    {
      services.netbird.server = {
        enable = true;

        domain = "netbird.olympus.moe";

        enableNginx = false;

        coturn = {
          enable = true;
          domain = "netbird.olympus.moe";
          passwordFile = config.sops.secrets."netbird/coturn/pass".path;
        };

        management = {
          turnDomain = "netbird.olympus.moe";
          oidcConfigEndpoint = "https://sso.olympus.moe/.well-known/openid-configuration";

          settings = {
            HttpConfig.AuthAudience = "e68e5a15-3877-4f42-b2fe-0523261107da";

            DeviceAuthorizationFlow.Provider = "none";

            PKCEAuthorizationFlow = {
              Provider = "hosted";
              ProviderConfig = {
                ClientID = "e68e5a15-3877-4f42-b2fe-0523261107da";
                ClientSecret = "";
              };
              RedirectURLs = [
                "http://localhost:53000"
                "http://localhost:54000"
                "https://netbird.olympus.moe/auth"
              ];
            };

            TURNConfig = {
              Turns = [
                {
                  Proto = "udp";
                  URI = "turn:netbird.olympus.moe:3478";
                  Username = "netbird";
                  Password._secret = config.sops.secrets."netbird/TURN/pass".path;
                }
              ];
              Secret = {
                _secret = config.sops.secrets."netbird/turnsecret".path;
              };
            };

            IdpManagerConfig = {
              ManagerType = "pocketid";
              ExtraConfig = {
                ManagementEndpoint = "https://sso.olympus.moe";
                ApiToken = {
                  _secret = config.sops.secrets."netbird/idp/apitoken".path;
                };
              };
            };

            DataStoreEncryptionKey = {
              _secret = config.sops.secrets."netbird/datastore/encryption".path;
            };

            Relay = {
              Addresses = [ "rel://netbird.olympus.moe:33093" ];
              CredentialsTTL = "24h0m0s";
              Secret = {
                _secret = config.sops.secrets."netbird/relay/secret".path;
              };
            };
          };

          logLevel = "DEBUG";
        };

        dashboard = {
          enable = true;
          settings = {
            AUTH_AUTHORITY = "https://sso.olympus.moe";
            AUTH_CLIENT_ID = "e68e5a15-3877-4f42-b2fe-0523261107da";
            AUTH_AUDIENCE = "";
            AUTH_REDIRECT_URI = "/auth";
            AUTH_SILENT_REDIRECT_URI = "/silent-auth";
          };
        };

        management.metricsPort = 13090;

        signal.port = 8012;

        management.package = pkgs-unstable.netbird-management;
        signal.package = pkgs-unstable.netbird-signal;
        dashboard.package = pkgs-unstable.netbird-dashboard;
      };

      # Relay covers peers that can't P2P (nyx has no public IP; coturn was never
      # reachable through aether's ingress). Plain rel:// rides the encrypted
      # wireguard payload over aether's caddy l4 passthrough. Hand-rolled unit:
      # this host's nixpkgs-26.05 module set has no services.netbird.relay option.
      systemd.services.netbird-relay = {
        description = "Relay for Netbird, a wireguard VPN";
        documentation = [ "https://netbird.io/docs/" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script =
          let
            args = lib.strings.concatStringsSep " " [
              "--listen-address :33080"
              "--exposed-address rel://netbird.olympus.moe:33093"
              "--health-listen-address :9000"
              "--log-level info"
            ];
          in
          ''
            export NB_AUTH_SECRET="$(< "$CREDENTIALS_DIRECTORY/auth_secret")"
            exec ${pkgs-unstable.netbird-relay}/bin/netbird-relay ${args}
          '';
        unitConfig = {
          StartLimitIntervalSec = 60;
          StartLimitBurst = 10;
        };
        serviceConfig = {
          LoadCredential = "auth_secret:${config.sops.secrets."netbird/relay/secret".path}";
          Restart = "always";
          RestartSec = "5s";
          DynamicUser = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateMounts = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProcSubset = "pid";
          ProtectSystem = "strict";
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
        };
      };

      services.coturn = {
        listening-ips = [ "172.17.100.1" ];
        relay-ips = [ "172.17.100.1" ];
        extraConfig = "external-ip=107.174.36.56/172.17.100.1";
      };

      networking.firewall = {
        allowedTCPPorts = [ 33080 ];
        allowedUDPPorts = [
          3478
        ];
      };

      networking.firewall.allowedUDPPortRanges = [
        {
          from = 49152;
          to = 65535;
        }
      ];

      users.users = {
        netbird = {
          isSystemUser = true;
          group = "netbird";
        };
        turnserver = {
          isSystemUser = true;
          group = "turnserver";
        };
      };

      users.groups.netbird = { };
    };

  # Coturn runs on the public-IP server (aether), not on the control plane
  # host: peers reach TURN on 107.174.36.56:3478 directly, so no NAT
  # port-forwards and no external-ip mapping are needed. Management (nyx)
  # keeps advertising turn:netbird.olympus.moe:3478 — that name resolves
  # to aether's public IP.
  flake.nixosModules.netbirdCoturn =
    {
      config,
      ...
    }:
    {
      services.netbird.server.coturn = {
        enable = true;
        domain = "netbird.olympus.moe";
        passwordFile = config.sops.secrets."netbird/coturn/pass".path;
        openPorts = [ 3478 ];
      };

      networking.firewall.allowedUDPPortRanges = [
        {
          from = 49152;
          to = 65535;
        }
      ];

      systemd.services.coturn = {
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
      };
    };
}
