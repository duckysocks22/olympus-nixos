{ inputs, ... }:
{
  flake.nixosModules.samba-local = { pkgs, config, ... }: {
    
    environment.systemPackages = [ pkgs.cifs-utils ];

    systemd.mounts = [
      {
        enable = true;
        description = "Olympus Shared SMB mount";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        what = "//172.17.100.1/shared";
        where = "/media/olympus/shared";
        options = "credentials=${config.sops.secrets."samba/local".path},uid=1000,gid=100,file_mode=0664,dir_mode=0775,nofail";
        type = "cifs";
        mountConfig.TimeoutSec = 15;
      }
      {
        enable = true;
        description = "Olympus Private SMB mount";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        what = "//172.17.100.1/private";
        where = "/media/olympus/private";
        options = "credentials=${config.sops.secrets."samba/local".path},uid=1000,gid=100,file_mode=0664,dir_mode=0775,nofail";
        type = "cifs";
        mountConfig.TimeoutSec = 15;
      }
    ];
  };
}
