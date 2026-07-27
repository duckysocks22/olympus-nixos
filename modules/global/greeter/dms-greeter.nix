{ pkgs, config, inputs, ... }:
{
  programs.dank-material-shell.greeter = {
    enable = true;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

    configFiles = [
      "${config.users.users.foxtrot.home}/.config/DankMaterialShell/settings.json"
    ];

    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };

    quickshell.package = pkgs.quickshell;
  };

  environment.systemPackages = [ pkgs.bibata-cursors ];
}
