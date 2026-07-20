{ pkgs, config, ... }:
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  systemd.mounts = [
    {
      description = "Olympus Shared SMB mount";
      what = "//172.17.100.1/shared";
      where = "/media/olympus/shared";
      options = "credentials=${
        config.sops.secrets."samba/local".path
      },uid=1000,gid=100,file_mode=0664,dir_mode=0775,x-systemd.automount,noauto,x-systemd.device-timeout=5s";
      type = "cifs";
      after = [
        "sops-install-secrets.service"
        "network-online.target"
      ];
      requires = [ "sops-install-secrets.service" ];
      wants = [ "network-online.target" ];
    }
    {
      description = "Olympus Private SMB mount";
      what = "//172.17.100.1/private";
      where = "/media/olympus/private";
      options = "credentials=${
        config.sops.secrets."samba/local".path
      },uid=1000,gid=100,file_mode=0664,dir_mode=0775,x-systemd.automount,noauto,x-systemd.device-timeout=5s";
      type = "cifs";
      after = [
        "sops-install-secrets.service"
        "network-online.target"
      ];
      requires = [ "sops-install-secrets.service" ];
      wants = [ "network-online.target" ];
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      where = "/media/olympus/shared";
    }
    {
      wantedBy = [ "multi-user.target" ];
      where = "/media/olympus/private";
    }
  ];

}
