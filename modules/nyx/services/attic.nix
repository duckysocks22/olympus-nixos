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

  services.atticd = {
    enable = true;
    environmentFile = "${config.sops.secrets."attic/server-token".path}";
    package = pkgs-unstable.attic-server;

    settings = {
      listen = "[::]:7989";
      api-endpoint = "https://cache.puppygirls.net/";

      # Use PostgreSQL instead of SQLite — SQLite serialises all writes behind a
      # single file lock, causing pool timeouts when Nix pushes many chunks in
      # parallel.  PostgreSQL handles concurrent writes correctly.
      database.url = "postgresql:///attic?host=/run/postgresql";

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

  # Ensure PostgreSQL doesn't start before /media/hdd1 is mounted — the attic
  # tablespace lives there, so a premature start would leave it in an error state.
  # Use explicit mount unit ordering rather than RequiresMountsFor (which the
  # postgresql module already sets for its own dataDir and doesn't merge).
  systemd.services.postgresql.after = [ "media-hdd1.mount" ];
  systemd.services.postgresql.requires = [ "media-hdd1.mount" ];
  # PostgreSQL's ProtectSystem sandboxing makes the tablespace path read-only by
  # default; explicitly allow writes there so CREATE TABLESPACE can chmod it.
  systemd.services.postgresql.serviceConfig.ReadWritePaths = [ "/media/hdd1/cache/attic-db" ];

  # One-shot service that idempotently bootstraps the attic PostgreSQL database.
  # Runs after PostgreSQL is up, before atticd starts.
  systemd.services.attic-db-setup = {
    description = "Bootstrap attic PostgreSQL database and tablespace";
    after = [ "postgresql.service" ];
    # Pull this service in whenever atticd is wanted, and ensure it finishes first.
    wantedBy = [ "atticd.service" ];
    before = [ "atticd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      # Create the tablespace directory as root before dropping to the postgres
      # user — PostgreSQL requires mode 0700 and postgres ownership.
      ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o postgres -g postgres /media/hdd1/cache/attic-db";
    };
    path = [ config.services.postgresql.package ];
    script = ''
      # The system glibc collation version may differ from what PostgreSQL recorded
      # at initdb time (e.g. after a glibc upgrade). Refreshing the version metadata
      # is safe and required before CREATE DATABASE will succeed.
      psql -c "ALTER DATABASE template1 REFRESH COLLATION VERSION" || true
      psql -c "ALTER DATABASE postgres REFRESH COLLATION VERSION" || true

      # Create the atticd PostgreSQL role if it doesn't exist.
      psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'atticd'" \
        | grep -q 1 || psql -c "CREATE USER atticd"

      # Create the tablespace pointing at the hdd1 directory if it doesn't exist.
      psql -tc "SELECT 1 FROM pg_tablespace WHERE spcname = 'attic'" \
        | grep -q 1 || psql -c "CREATE TABLESPACE attic LOCATION '/media/hdd1/cache/attic-db'"

      # Create the attic database in the hdd1 tablespace if it doesn't exist.
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
}
