{ inputs, ...}:
{
    imports = [ inputs.copyparty.nixosModules.default ];
    services.copyparty = {
      enable = true;
      user = "server";
      group = "users";
      settings = {
        i = "0.0.0.0";
        p = [ 3210 3211 ];
        no-reload = true;
        ignored-flag = false;
      };

      accounts = {
        socks = {
          passwordFile = "/home/server/keys/copyparty/socks_password";
        };
        serena = {
          passwordFile = "/home/server/keys/copyparty/serena_password";
        };
        zia = {
          passwordFile = "/home/server/keys/copyparty/zia_password";
        };
      };

      groups = {
        users = [ "socks" ];
        admins = [ "socks" ];
      };

      volumes = {
        "/" = {
          path = "/media/hdd1/copyparty";

          access = {
            r = "*";

            rwd = [ "socks" ];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
        };

        "/shared" = {
          path = "/media/hdd1/copyparty/shared";

          access = {
            rwd = "*";
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
        };

       "/private" = {
          path = "/media/hdd1/copyparty/private";

          access = {
            rwd = [ "socks"];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
        };

        "/ludusavi" = {
          path = "/media/hdd1/copyparty/ludusavi";

          access = {
            rwd = [ "socks" ];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
            dots = true;
            dotsrch = true;
          };
          
        };

        "/phonebackup" = {
          path = "/media/hdd1/copyparty/phonebackup";

          access = {
            rwd = [ "socks" ];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
            dots = true;
            dotssrch = true;
          };
          
        };

      };
      openFilesLimit = 8192;
    };
}
