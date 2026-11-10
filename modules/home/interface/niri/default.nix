{ inputs, self, ... }:
{
  flake.homeModules.niri =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.niri.homeModules.config

        inputs.self.homeModules.dms
        inputs.self.homeModules.niriCursors
      ];

      programs.niri = {
        package = pkgs.niri;
        settings = {
          outputs = {
            "PNP(AOC) CU34G2XP 1Q1R9UA004091" = {
              mode = {
                width = 3440;
                height = 1440;
                refresh = 180.0;
              };
              position = {
                x = 0;
                y = -0;
              };
              scale = 1.1;
              variable-refresh-rate = "on-demand";
              focus-at-startup = true;
            };
            "Acer Technologies Acer XFA240 0x91001AB2" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 119.982;
              };
              position = {
                x = 1920;
                y = 200;
              };
              variable-refresh-rate = "on-demand";
            };
            DP-1 = {
              mode = {
                width = 3840;
                height = 2160;
                refresh = 119.892;
              };
              enable = false;
            };
          };
          prefer-no-csd = true;
          hotkey-overlay.skip-at-startup = true;
          input.focus-follows-mouse.enable = true;
          input.mouse = {
            accel-speed = 0.1;
            accel-profile = "flat";
          };
          layout = {
            gaps = 8;
            background-color = "transparent";
            center-focused-column = "never";
            preset-column-widths = [
              { proportion = 0.33333; }
              { proportion = 0.5; }
              { proportion = 0.66667; }
            ];
            default-column-width = {
              proportion = 0.5;
            };
            border = {
              enable = false;
              width = 4;
              active.color = "#707070";
              inactive.color = "#d0d0d0";
              urgent.color = "#cc4444";
            };
            focus-ring = {
              width = 2;
              active.color = "#808080";
              inactive.color = "#505050";
            };
            shadow = {
              softness = 30;
              spread = 5;
              offset = {
                x = 0;
                y = 5;
              };
              color = "#0007";
            };
            struts = { };
          };
          spawn-at-startup = [
            { argv = [ "netbird-ui-wt0" ]; }
          ];
          window-rules = [
            {
              matches = [ { app-id = "^org\\.wezfurlong\\.wezterm$"; } ];
              default-column-width = { };
            }
            {
              matches = [ { app-id = "^org\\.gnome\\."; } ];
              draw-border-with-background = false;
              geometry-corner-radius = {
                top-left = 12.0;
                top-right = 12.0;
                bottom-left = 12.0;
                bottom-right = 12.0;
              };
              clip-to-geometry = true;
            }
            {
              matches = [
                { app-id = "^gnome-control-center$"; }
                { app-id = "^pavucontrol$"; }
                { app-id = "^nm-connection-editor$"; }
              ];
              default-column-width = {
                proportion = 0.5;
              };
              open-floating = false;
            }
            {
              matches = [
                { app-id = "^gnome-calculator$"; }
                { app-id = "^galculator$"; }
                { app-id = "^blueman-manager$"; }
                { app-id = "^org\\.gnome\\.Nautilus$"; }
                { app-id = "^xdg-desktop-portal$"; }
              ];
              open-floating = true;
            }
            {
              matches = [
                { app-id = "^org\\.wezfurlong\\.wezterm$"; }
                { app-id = "Alacritty"; }
                { app-id = "zen"; }
                { app-id = "com.mitchellh.ghostty"; }
                { app-id = "kitty"; }
              ];
              draw-border-with-background = false;
            }
            {
              matches = [ { is-active = false; } ];
              opacity = 0.9;
            }
            {
              matches = [
                {
                  app-id = "librewolf$";
                  title = "^Picture-in-Picture$";
                }
                { app-id = "zoom"; }
              ];
              open-floating = true;
            }
            {
              matches = [
                { app-id = "Minecraft"; }
                { app-id = "yarc-launcher"; }
                { title = "Satisfactory  "; }
                { app-id = "factorio"; }
                { app-id = "steam_app_4576510"; }
                { app-id = "gamescope"; }
                { app-id = "ffxiv_dx11.exe"; }
              ];
              open-fullscreen = true;
              open-floating = true;
            }
            {
              matches = [
                { app-id = "unityhub"; }
                { app-id = "com.bitwig.BitwigStudio"; }
                { app-id = "synthv-studio.exe"; }
                { app-id = "wlfreerdp"; }
                { title = "FreeRDP"; }
                { app-id = "jellyfin-desktop"; }
              ];
              open-maximized = true;
            }
            {
              matches = [
                { app-id = "librewolf"; }
                { app-id = "jellyfin-desktop"; }
              ];
              opacity = 1.0;
            }
            {
              geometry-corner-radius = {
                top-left = 12.0;
                top-right = 12.0;
                bottom-left = 12.0;
                bottom-right = 12.0;
              };
              clip-to-geometry = true;
            }
          ];
          layer-rules = [
            {
              matches = [ { namespace = "^quickshell$"; } ];
              place-within-backdrop = true;
            }
          ];
          overview = {
            workspace-shadow.enable = false;
          };
          binds = {
            # -- System & Overview ---
            "Mod+D" = {
              action.spawn = [
                "niri"
                "msg"
                "action"
                "toggle-overview"
              ];
            };
            "Mod+Tab" = {
              repeat = false;
              action.toggle-overview = { };
            };
            "Mod+Shift+Slash".action.show-hotkey-overlay = { };

            # --- Application Launchers ---
            "Mod+Q" = {
              hotkey-overlay = {
                title = "Open Terminal";
              };
              action.spawn = "kitty";
            };
            "Mod+R" = {
              hotkey-overlay = {
                title = "Application Launcher";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "launcher"
                "toggle"
              ];
            };
            "Mod+V" = {
              hotkey-overlay = {
                title = "Clipboard Manager";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "spotlight"
                "toggle"
              ];
            };
            "Mod+M" = {
              hotkey-overlay = {
                title = "Task Manager";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "processlist"
                "toggle"
              ];
            };
            "Mod+Comma" = {
              hotkey-overlay = {
                title = "Settings";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "settings"
                "toggle"
              ];
            };
            "Mod+Y" = {
              hotkey-overlay = {
                title = "Browse Wallpapers";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "dankdash"
                "wallpaper"
              ];
            };
            "Mod+N" = {
              hotkey-overlay = {
                title = "Notification Center";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "notifications"
                "toggle"
              ];
            };
            "Mod+Shift+N" = {
              hotkey-overlay = {
                title = "Notepad";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "notepad"
                "toggle"
              ];
            };
            "Mod+E" = {
              hotkey-overlay = {
                title = "Open Thunar";
              };
              action.spawn = "dolphin";
            };
            "Mod+B" = {
              hotkey-overlay = {
                title = "Open Librewolf";
              };
              action.spawn = "librewolf";
            };

            # --- Security ---
            "Mod+L" = {
              hotkey-overlay = {
                title = "Lock Screen";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "lock"
                "lock"
              ];
            };
            "Mod+Shift+E".action.quit = { };
            "Ctrl+Alt+Delete" = {
              hotkey-overlay = {
                title = "Task Manager";
              };
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "processlist"
                "toggle"
              ];
            };

            # --- Audio Controls ---
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "audio"
                "increment"
                "3"
              ];
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "audio"
                "decrement"
                "3"
              ];
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "audio"
                "mute"
              ];
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "audio"
                "micmute"
              ];
            };
            "XF86KbdBrightnessUp" = {
              allow-when-locked = true;
              action.spawn = [
                "kbdbrite.sh"
                "up"
              ];
            };
            "XF86KbdBrightnessDown" = {
              allow-when-locked = true;
              action.spawn = [
                "kbdbrite.sh"
                "down"
              ];
            };

            # --- Brightness ---
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "brightness"
                "increment"
                "5"
                ""
              ];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "brightness"
                "decrement"
                "5"
                ""
              ];
            };

            # --- Window Management ---
            "Mod+C" = {
              repeat = false;
              action.close-window = { };
            };
            "Mod+F".action.maximize-column = { };
            "Mod+Shift+F".action.fullscreen-window = { };
            "Mod+Shift+T".action.toggle-window-floating = { };
            "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };
            "Mod+W".action.toggle-column-tabbed-display = { };

            # --- Focus Navigation ---
            "Mod+Left".action.focus-column-left = { };
            "Mod+Down".action.focus-window-down = { };
            "Mod+Up".action.focus-window-up = { };
            "Mod+Right".action.focus-column-right = { };
            "Mod+H".action.focus-column-left = { };
            "Mod+J".action.focus-window-down = { };
            "Mod+K".action.focus-window-up = { };

            # --- Window Movement ---
            "Mod+Shift+Left".action.move-column-left = { };
            "Mod+Shift+Down".action.move-window-down = { };
            "Mod+Shift+Up".action.move-window-up = { };
            "Mod+Shift+Right".action.move-column-right = { };
            "Mod+Shift+H".action.move-column-left = { };
            "Mod+Shift+J".action.move-window-down = { };
            "Mod+Shift+K".action.move-window-up = { };
            "Mod+Shift+L".action.move-column-right = { };

            # --- Column Navigation ---
            "Mod+Home".action.focus-column-first = { };
            "Mod+End".action.focus-column-last = { };
            "Mod+Ctrl+Home".action.move-column-to-first = { };
            "Mod+Ctrl+End".action.move-column-to-last = { };

            # --- Monitor Navigation ---
            "Mod+Ctrl+Left".action.focus-monitor-left = { };
            "Mod+Ctrl+Right".action.focus-monitor-right = { };
            "Mod+Ctrl+H".action.focus-monitor-left = { };
            "Mod+Ctrl+J".action.focus-monitor-down = { };
            "Mod+Ctrl+K".action.focus-monitor-up = { };
            "Mod+Ctrl+L".action.focus-monitor-right = { };

            # --- Move to Monitor ---
            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
            "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

            # --- Workspace Navigation ---
            "Mod+Page_Down".action.focus-workspace-down = { };
            "Mod+Page_Up".action.focus-workspace-up = { };
            "Mod+U".action.focus-workspace-down = { };
            "Mod+I".action.focus-workspace-up = { };
            "Mod+Ctrl+Down".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+Up".action.move-column-to-workspace-up = { };
            "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

            # --- Move Workspaces ---
            "Mod+Shift+Page_Down".action.move-workspace-down = { };
            "Mod+Shift+Page_Up".action.move-workspace-up = { };
            "Mod+Shift+U".action.move-workspace-down = { };
            "Mod+Shift+I".action.move-workspace-up = { };

            # --- Mouse Wheel Navigation ---
            "Mod+WheelScrollDown".action.focus-column-right = { };
            "Mod+WheelScrollUp".action.focus-column-left = { };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = { };
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = { };
            };
            "Mod+WheelScrollRight".action.focus-column-right = { };
            "Mod+WheelScrollLeft".action.focus-column-left = { };
            "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
            "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
            "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
            "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
            "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
            "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

            # --- Numbered Workspaces ---
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            # --- Move to Numbered Workspaces ---
            "Mod+Shift+1".action.move-column-to-workspace = 1;
            "Mod+Shift+2".action.move-column-to-workspace = 2;
            "Mod+Shift+3".action.move-column-to-workspace = 3;
            "Mod+Shift+4".action.move-column-to-workspace = 4;
            "Mod+Shift+5".action.move-column-to-workspace = 5;
            "Mod+Shift+6".action.move-column-to-workspace = 6;
            "Mod+Shift+7".action.move-column-to-workspace = 7;
            "Mod+Shift+8".action.move-column-to-workspace = 8;
            "Mod+Shift+9".action.move-column-to-workspace = 9;

            # --- Column Management ---
            "Mod+BracketLeft".action.consume-or-expel-window-left = { };
            "Mod+BracketRight".action.consume-or-expel-window-right = { };
            "Mod+Period".action.expel-window-from-column = { };

            # --- Sizing & Layout ---
            "Mod+Shift+R".action.switch-preset-window-height = { };
            "Mod+Ctrl+R".action.reset-window-height = { };
            "Mod+Ctrl+F".action.expand-column-to-available-width = { };
            "Mod+Ctrl+C".action.center-visible-columns = { };

            # --- Manual Sizing ---
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

            # --- Screenshots ---
            "XF86Launch1".action.screenshot = { };
            "Ctrl+XF86Launch1".action.screenshot-screen = { };
            "Alt+XF86Launch1".action.screenshot-window = { };
            "Print".action.screenshot = { };
            "Ctrl+Print".action.screenshot-screen = { };
            "Alt+Print".action.screenshot-window = { };
            "Mod+Shift+S".action.screenshot = { };

            # --- Screen Recording / System ---
            "F12".action.spawn = [
              "pkill"
              "-SIGRTMIN+4"
              "-f"
              "gpu-screen-recorder"
            ];
            "Mod+Escape" = {
              allow-inhibiting = false;
              action.toggle-keyboard-shortcuts-inhibit = { };
            };
            "Mod+Shift+P".action.power-off-monitors = { };
          };
        };
      };

      # Patch the niri config afterwards to add per monitor default proportions
      xdg.configFile.niri-config.source = lib.mkForce (
        let
          widths = {
            "PNP(AOC) CU34G2XP 1Q1R9UA004091" = "0.33";
          };

          patched = lib.foldl' (
            text: name:
            lib.replaceStrings
              [ ''output "${name}" {'' ]
              [
                ''
                  output "${name}" {
                      layout {
                          default-column-width { proportion ${widths.${name}}; }
                      }''
              ]
              text
          ) config.programs.niri.finalConfig (builtins.attrNames widths);
        in
        pkgs.runCommand "niri-config.kdl" { buildInputs = [ config.programs.niri.package ]; } ''
          cp ${pkgs.writeText "niri-config.kdl.in" patched} $out
          niri validate -c $out
        ''
      );

      home.packages = with pkgs; [
        niri
        dconf
        slurp
        libnotify
        xwayland-satellite
      ];

      gtk = {
        enable = true;
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      dconf = {
        enable = true;
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
        };
      };

      services.polkit-gnome.enable = true;
    };
}
