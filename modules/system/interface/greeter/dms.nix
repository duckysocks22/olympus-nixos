{ inputs, self, ... }:
{
  flake.nixosModules.dms-greeter =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.dank-greeter.nixosModules.default ];

      programs.dms-greeter = {
        enable = true;
        compositor = {
          name = "niri";
          customConfig = ''
            cursor {
              xcursor-theme "Bibata-Modern-Ice"
              xcursor-size 18

              hide-when-typing
              hide-after-inactive-ms 1000
            }

            hotkey-overlay {
              skip-at-startup
            }

            gestures {
              hot-corners {
                off
              }
            }

            layout {
              background-color "#000000"
            }

            environment {
              DMS_RUN_GREETER "1"
            }
          '';
        };

        configHome = "${config.users.users.foxtrot.home}";

        logs = {
          save = true;
          path = "/tmp/dms-greeter.log";
        };
      };

      environment.systemPackages = [ pkgs.bibata-cursors ];

      services.accounts-daemon.enable = true;

      system.activationScripts.dmsProfilePicture = lib.stringAfter [ "users" ] ''
        mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
        ln -sfn "${
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.assets
        }/share/assets/pfp/argyle_shaded.png" /var/lib/AccountsService/icons/foxtrot
        cat > /var/lib/AccountsService/users/foxtrot <<'EOF'
        [User]
        SystemAccount=false
        Icon=/var/lib/AccountsService/icons/foxtrot
        EOF
      '';
    };
}
