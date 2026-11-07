{ inputs, self, ... }:
{
  flake.nixosModules.atticd =
    {
      inputs,
      pkgs,
      pkgs-unstable,
      config,
      lib,
      ...
    }:
    {
      imports = [
        inputs.attic.nixosModules.atticd
      ];

      environment.systemPackages =
        (with pkgs; [

        ])
        ++ (with pkgs-unstable; [
          attic-server
        ]);

      nix.settings.substituters = [ "http://localhost:7989/main" ];

      services.atticd = {
        enable = true;
        environmentFile = "${config.sops.secrets."attic/server-token".path}";
        package = pkgs-unstable.attic-server;

        settings = {
          listen = "[::]:7989";
          api-endpoint = "https://cache.puppygirls.net/";

          database.url = "postgresql:///attic?host=/run/postgresql&user=atticd";

          storage = {
            type = "local";
            path = "/media/hdd1/cache/";
          };

          garbage-collection = {
            interval = "48h";
          };

          jwt = { };

          chunking = {
            nar-size-threshold = 64 * 1024; # 64 KiB
            min-size = 16 * 1024; # 16 KiB
            avg-size = 64 * 1024; # 64 KiB
            max-size = 256 * 1024; # 256 KiB
          };
        };
      };

      services.postgresql.enable = true;

      systemd.services.postgresql.after = [ "media-hdd1.mount" ];
      systemd.services.postgresql.requires = [ "media-hdd1.mount" ];
      systemd.services.postgresql.serviceConfig.ReadWritePaths = [ "/media/hdd1/cache/attic-db" ];

      systemd.services.attic-db-setup = {
        description = "Bootstrap attic PostgreSQL database and tablespace";
        after = [ "postgresql.service" ];
        wantedBy = [ "atticd.service" ];
        before = [ "atticd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
          ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o postgres -g postgres /media/hdd1/cache/attic-db";
        };
        path = [ config.services.postgresql.package ];
        script = ''
          psql -c "ALTER DATABASE template1 REFRESH COLLATION VERSION" || true
          psql -c "ALTER DATABASE postgres REFRESH COLLATION VERSION" || true

          psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'atticd'" \
            | grep -q 1 || psql -c "CREATE USER atticd"

          psql -tc "SELECT 1 FROM pg_tablespace WHERE spcname = 'attic'" \
            | grep -q 1 || psql -c "CREATE TABLESPACE attic LOCATION '/media/hdd1/cache/attic-db'"

          psql -tc "SELECT 1 FROM pg_database WHERE datname = 'attic'" \
            | grep -q 1 || psql -c "CREATE DATABASE attic TABLESPACE attic OWNER atticd"
        '';
      };

      systemd.services.atticd = {
        after = [ "attic-db-setup.service" ];
        requires = [ "attic-db-setup.service" ];
        serviceConfig = {
          ReadWritePaths = [ "/media/hdd1/cache" ];
          ProtectHome = lib.mkForce false;
          ProtectSystem = lib.mkForce "full";
        };
      };
    };
}
