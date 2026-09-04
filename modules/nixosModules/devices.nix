{ inputs, self, ... }: {
  flake.nixosModules.localPrinting = { pkgs, ... }: {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
        canon-cups-ufr2
      ];
    };

    hardware.printers.ensurePrinters = [
      {
        name = "Canon-MF270";
        description = "Canon MF270 Series";
        deviceUri = "dnssd://Canon%20MF270%20Series._ipp._tcp.local/?uuid=6d4ff0ce-6b11-11d8-8020-6c3c7c3bf858";
        model = "CNRCUPSMF270ZK.ppd";
      }
    ];
    hardware.printers.ensureDefaultPrinter = "Canon-MF270";
  };

  flake.nixosModules.localSamba = { pkgs, config, ... }: {
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
  };
}
