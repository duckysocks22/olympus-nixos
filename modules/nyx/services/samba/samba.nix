{

  imports = [
    # Users
    ./users/socks.nix
    ./users/zia.nix
    ./users/serena.nix
  ];
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nyxsmb";
        "netbios name" = "nyxsmb";
        "security" = "user";
        "hosts allow" = "172.17.0.";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "obey pam restrictions" = "no";
      };
      "shared" = {
        "path" = "/media/hdd1/shares/shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest okay" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "private" = {
        "path" = "/media/hdd1/shares/private";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "socks";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
