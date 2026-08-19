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

  systemd.services.cifs-watchdog = {
    description = "Unmount dead Olympus SMB shares";
    serviceConfig.Type = "oneshot";
    script = ''
      if ! ${pkgs.coreutils}/bin/timeout 2 ${pkgs.bash}/bin/bash -c '</dev/tcp/172.17.100.1/445' 2>/dev/null; then
        for m in /media/olympus/shared /media/olympus/private; do
          if ${pkgs.util-linux}/bin/mountpoint -q "$m"; then
            ${pkgs.util-linux}/bin/umount -l "$m" || true
            echo "NAS 172.17.100.1 unreachable: lazily unmounted $m"
          fi
        done
      fi
    '';
  };

  systemd.timers.cifs-watchdog = {
    description = "Poll for dead Olympus SMB shares";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "2min";
      AccuracySec = "10s";
    };
  };

}
