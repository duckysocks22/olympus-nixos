{ inputs, self, ... }:
{
  flake.nixosModules.copyparty =
    {
      inputs,
      config,
      ...
    }:
    {
      imports = [ inputs.copyparty.nixosModules.default ];

      # Pillow 13 rejects fromarray(mode=...) on 16-bit I;16 images, failing the
      # test suites of pillow-jpls and imageio (copyparty's thumbnail deps).
      # Drop just those tests until nixpkgs patches both packages.
      nixpkgs.overlays = [
        (final: prev: {
          copyparty = prev.copyparty.override {
            python3Packages = prev.python3Packages.override {
              overrides = _pyFinal: pyPrev: {
                pillow-jpls = pyPrev.pillow-jpls.overridePythonAttrs (_: {
                  disabledTests = [ "test_encode_with_spiff_header" ];
                });
                imageio = pyPrev.imageio.overridePythonAttrs (_: {
                  disabledTests = [ "test_png" ];
                });
              };
            };
          };
        })
      ];

      services.copyparty = {
        enable = true;
        user = "copyparty";
        group = "users";
        settings = {
          i = "0.0.0.0";
          p = [
            3210
            3211
          ];
          xff-hdr = "X-Forwarded-For";
          xff-src = "127.0.0.1";
          rproxy = 1;
          no-reload = true;
          ignored-flag = false;
        };

        accounts = {
          socks = {
            passwordFile = "${config.sops.secrets."copyparty/foxtrot".path}";
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
              nohash = ".iso$";
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
              nohash = ".iso$";
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
              nohash = ".iso$";
              dots = true;
              dotssrch = true;
            };

          };

          "/olympus_shared" = {
            path = "/media/hdd1/shares/shared";

            access = {
              rwd = [ "socks" ];
            };

            flags = {
              fk = 4;
              scan = 30;
              e2d = true;
              d2t = true;
              nohash = ".iso$";
              dots = true;
              dostsrch = true;
            };
          };
        };
        openFilesLimit = 8192;
      };
    };
}
