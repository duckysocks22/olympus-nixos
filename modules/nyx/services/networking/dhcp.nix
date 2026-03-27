{
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [
            "enp34s0"
          ];
        };
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        rebind-timer = 2000;
        renew-timer = 1000;
        subnet4 = [
          {
            id = 1;
            pools = [
              {
                pool = "172.17.0.10 - 172.17.0.240";
                option-data = [
                  {
                    name = "domain-name-servers";
                    data = "172.17.100.1";
                  }
                ];
              }
            ];
            subnet = "172.17.0.0/16";
            option-data = [
              {
                name = "routers";
                data = "172.17.0.254";
              }
            ];
          }
        ];
        valid-lifetime = 4000;
      };
    };
  };
}
