{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
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

  services.greetd.greeterManagesPlymouth = true;

  systemd.services.plymouth-quit = {
    wantedBy = lib.mkForce [ "graphical.target" ];
    after = lib.mkForce [
      "plymouth-start.service"
      "greetd.service"
    ];
    restartIfChanged = false;
    serviceConfig = {
      TimeoutSec = "60";
      ExecStart = lib.mkForce "-${pkgs.writeShellScript "plymouth-quit-after-greeter" ''
        for ((i = 0; i < 120; i++)); do
          ${pkgs.procps}/bin/pgrep -u greeter >/dev/null 2>&1 && break
          ${pkgs.coreutils}/bin/sleep 0.25
        done
        ${pkgs.coreutils}/bin/sleep 4
        exec ${pkgs.plymouth}/bin/plymouth quit
      ''}";
    };
  };

  systemd.services.plymouth-quit-wait.wantedBy = lib.mkForce [ ];

  environment.systemPackages = [ pkgs.bibata-cursors ];
}
