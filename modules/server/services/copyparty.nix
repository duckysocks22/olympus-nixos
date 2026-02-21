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
          passwordFile = "/run/keys/copyparty/socks_password";
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

            rw = [ "socks" ];
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
            r = "*";

            rw = [ "socks" ];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
          
        };

        "/phonebackup" = {
          path = "/media/hdd1/copyparty/phonebackup";

          access = {
            r = "*";

            rw = [ "socks" ];
          };

          flags = {
            fk = 4;
            scan = 30;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
          
        };

      };
      openFilesLimit = 8192;
    };
}
