{ pkgs, ... }:
{

  imports = [
    # Users
    ./users/socks.nix
    ./users/zia.nix
    ./users/serena.nix
    ./users/share.nix
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
        "hosts allow" = "172.17.0.0/16";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "share";
        "map to guest" = "bad user";
        "obey pam restrictions" = "no";
        "inherit permissions" = "yes";
        "inherit acls" = "yes";
      };
      "shared" = {
        "path" = "/media/hdd1/shares/shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force create mode" = "0664";
        "force directory mode" = "0775";
        "force user" = "share";
        "force group" = "users";
      };
      "private" = {
        "path" = "/media/hdd1/shares/private";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0755";
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
