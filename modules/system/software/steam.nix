{ inputs, self, ... }:
{
  flake.nixosModules.steam =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs = {
        gamescope.enable = true;

        steam = {
          enable = true;
          package = lib.mkIf (!(config ? jovian)) (
            pkgs.steam.override {
              extraProfile = ''
                export LD_LIBRARY_PATH=${
                  lib.makeLibraryPath [ pkgs.sdl2-compat ]
                }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
              '';

              extraBwrapArgs = [
                "--bind"
                "/dev/null"
                "/etc/ld-nix.so.preload"
              ];
            }
          );

          extraCompatPackages = with pkgs; [
            proton-ge-bin
            dwproton
            proton-em
            xlm
          ];
        };

        gamemode = {
          enable = true;

          settings = {
            general = {
              reaper_freq = 5;
              desiredgove = "powersave";
              desiredprof = "performance";
              igpu_desiredgov = -1;
              igpu_power_threshold = 0.3;
              softrealtime = "off";
              renice = 0;
              ioprio = 0;
              inhibit_screensaver = 1;
              disable_splitlock = 1;
            };

            gpu = {
              apply_gpu_optimisations = 0;
              amd_performance_leve = "high";
            };

            cpu = {
              park_cores = "no";
              pin_cores = "yes";
            };
          };
        };
      };

      environment.systemPackages =
        (with pkgs; [
          bubblewrap

          (writeShellScriptBin "gamescope_run" ''
            gamescope_args=()
            game_cmd=()
            sep_found=false

            for arg in "$@"; do
              if [[ "$arg" == "--" && "$sep_found" == "false" ]]; then
                sep_found=true
              elif [[ "$sep_found" == "true" ]]; then
                game_cmd+=("$arg")
              else
                gamescope_args+=("$arg")
              fi
            done

            # No -- provided: treat everything as the game command
            if [[ "$sep_found" == "false" ]]; then
              game_cmd=("''${gamescope_args[@]}")
              gamescope_args=()
            fi

            # gamescope is a nix binary: keep Steam's runtime paths out of it
            exec env LD_PRELOAD= LD_LIBRARY_PATH= ${pkgs.gamescope}/bin/gamescope \
              "''${gamescope_args[@]}" \
              -- env LD_PRELOAD="$LD_PRELOAD" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "''${game_cmd[@]}"
          '')
          (writeShellScriptBin "no-hardened" ''
            exec ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
              ${pkgs.runtimeShell} -c '
                ${pkgs.util-linux}/bin/mount --bind /dev/null /etc/ld-nix.so.preload
                exec "$@"
              ' no-hardened "$@"
          '')
        ])
        ++ (with inputs.reshade.packages.${pkgs.stdenv.hostPlatform.system}; [
          reshade
          reshade-shaders-full
        ]);
    };
}
