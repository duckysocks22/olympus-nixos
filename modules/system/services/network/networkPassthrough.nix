{ inputs, ... }:
{
  flake.nixosModules.networkPassthrough =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/mholt/caddy-l4@v0.1.2"
          ];
          hash = "sha256-FwGmHobFqBkEI7LN/YaPsL0t+dJn8uZMhCp9asDEsYw=";
        };
        environmentFile = "${config.sops.secrets."caddy/environment".path}";
        globalConfig = ''
          layer4 {
            :443 {
              route {
                proxy {
                  upstream 192.168.200.2:443
                }
              }
            }

            :80 {
              route {
                proxy {
                  upstream 192.168.200.2:80
                }
              }
            }

            :33093 {
              route {
                proxy {
                  upstream 192.168.200.2:33080
                }
              }
            }
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        33093
      ];
    };
}
