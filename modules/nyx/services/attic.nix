{ inputs, pkgs, pkgs-unstable, config, lib, ...}:
{

  imports = [
    inputs.attic.nixosModules.atticd
  ];

  environment.systemPackages = (with pkgs; [

  ]) ++ (with pkgs-unstable; [
    attic-server
  ]);

  services.atticd = {
    enable = true;
    environmentFile = "${config.sops.secrets."attic/server-token".path}";
    package = pkgs-unstable.attic-server;

    settings = {
      listen = "[::]:7989";
      
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

  systemd.services.atticd.serviceConfig = {
  ReadWritePaths = [ "/media/hdd1/cache" ];
  ProtectHome = lib.mkForce false;
  ProtectSystem = lib.mkForce "full"; 
  };
}
