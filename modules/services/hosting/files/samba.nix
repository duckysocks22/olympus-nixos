{ inputs, self, ... }:
{
  flake.nixosModules.samba =
    {
      config,
      pkgs,
      ...
    }:
    {
      services = {
        samba = {
          enable = true;
          openFirewall = true;
          settings = {
            global = {
              "workgroup" = "WORKGROUP";
              "server string" = "nyxsmb";
              "netbios name" = "nyxsmb";
              "security" = "user";
              "hosts allow" = "172.17.0.0/16 192.168.10.0/24";
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

        samba-wsdd = {
          enable = true;
          openFirewall = true;
        };
      };

      users = {
        users = {
          socks = {
            description = "Write-access to samba media shares";
            group = "socks";
            extraGroups = [ "users" ];
            hashedPasswordFile = config.sops.secrets."users/server".path;
            isSystemUser = true;
          };
          serena = {
            description = "Write-access to samba media shares";
            group = "serena";
            extraGroups = [ "users" ];
            hashedPasswordFile = config.sops.secrets."users/server".path;
            isSystemUser = true;
          };
          zia = {
            description = "Write-access to samba media shares";
            group = "zia";
            extraGroups = [ "users" ];
            hashedPasswordFile = config.sops.secrets."users/server".path;
            isSystemUser = true;
          };
        };
        groups = {
          socks = { };
          serena = { };
          zia = { };
        };
      };

      system.activationScripts = {
        init_smbpasswdSocks.text = ''
          /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/socks".path
          })\n$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/socks".path
          })\n" | /run/current-system/sw/bin/smbpasswd -sa socks
        '';
        init_smbpasswdSerena.text = ''
          /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/serena".path
          })\n$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/serena".path
          })\n" | /run/current-system/sw/bin/smbpasswd -sa serena
        '';
        init_smbpasswdZia.text = ''
          /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/zia".path
          })\n$(/run/current-system/sw/bin/cat ${
            config.sops.secrets."samba-nyx/zia".path
          })\n" | /run/current-system/sw/bin/smbpasswd -sa zia
        '';
      };
    };
}
