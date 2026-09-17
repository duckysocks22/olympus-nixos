{ inputs, self, ... }: {
  flake.nixosModules.system =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [
        self.nixosModules.nixSettings
        self.nixosModules.portals
        self.nixosModules.finalMouseUdev
      ];

      hardware.bluetooth = {
        enable = true;
        settings = {
          General = {
            FastConnectable = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };

      services = {
        tuned.enable = true;
        upower.enable = true;
        gnome.gnome-keyring.enable = true;
      };

      programs = {
        zsh.enable = true;
        gpu-screen-recorder.enable = true;
        dconf.enable = true;
      };

      environment.systemPackages = with pkgs; [
        gptfdisk
        gparted
        xfsprogs
        cifs-utils
        nix-prefetch-git
        curl
        p7zip
        python3
        mktorrent
        bashmount
        qt6.qtbase
        qt6.qtwayland
        qt6.qttools
        glibc
        fontconfig
        dbus
        gsettings-desktop-schemas
        gtk3
        tpm2-tss
        sbctl
        mesa.opencl
      ];

      environment.variables = {
        RUSTICL_ENABLE = "radeonsi";
      };

      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];

      security = {
        polkit.enable = true;
        pam.services.niri.enableGnomeKeyring = true;
        sudo = {
          extraConfig = "Defaults lecture = never";
          extraRules = [
            {
              users = [ "foxtrot" ];
              commands = [
                {
                  command = "/run/current-system/sw/bin/nixos-rebuild";
                  options = [ "NOPASSWD" ];
                }
                {
                  command = "${pkgs.nh}/bin/nh os switch";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];
        };
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.mesa.opencl ];
      };

      boot = {
        kernelPackages =
          let
            kernel = {
              "nyx-nixos" = pkgs.linuxPackages_latest;
              "aether-nixos" = pkgs.linuxPackages_latest;
              "athena-nixos" = rcKernel;
              "circe-nixos" = rcKernel;
            };
            rcKernel = pkgs.linuxPackagesFor (
              pkgs.linuxKernel.kernels.linux_7_2.override {
                argsOverride = rec {
                  src = pkgs.fetchurl {
                    url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-7.3-rc3.tar.gz";
                    sha256 = "sha256-SbJBGde5Ladbug2vXaT3c1yMuUh1eiguhJCS3MaB2N0=";
                  };
                  version = "7.3.0-rc3";
                  modDirVersion = "7.3.0-rc3";
                };
              }
            );
          in
          kernel.${config.networking.hostName} or (
            if config ? jovian then
              pkgs.linuxPackages_jovian
            else
              throw "system.nix: no kernelPackages entry for host ${config.networking.hostName}"
          );
        kernelModules = [
          "sg"
          "hid-tmff-new"
          "hid-tminit-new"
        ];
        kernelParams = [
          "amd_pstate=active"
          "quiet"
          "splash"
        ]
        ++
          lib.optionals
            (
              !(builtins.elem config.networking.hostName [
                "dionysus-nixos"
                "ariadne-nixos"
              ])
            )
            [
              "amd_iommu=on"
            ];
        loader = {
          limine = {
            enable = true;
            secureBoot.enable = false;
            efiInstallAsRemovable = true;
          };
          efi = {
            canTouchEfiVariables = false;
          };
        };
        plymouth = {
          enable = true;
          theme = "deus_ex";
          themePackages = with pkgs; [
            (adi1090x-plymouth-themes.override {
              selected_themes = [ "deus_ex" ];
            })
          ];
          extraConfig = ''
            [Daemon]
            DeviceScale=1.0
          '';
        };
      };
    };

  flake.nixosModules.common =
    {
      pkgs,
      pkgs-unstable,
      inputs,
      ...
    }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          extraBwrapArgs = [
            "--bind"
            "/dev/null"
            "/etc/ld-nix.so.preload"
          ];
        };
        extraCompatPackages =
          (with pkgs; [
            proton-ge-bin
          ])
          ++ [
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dwproton
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.proton-em
          ];
      };

      programs = {
        gamescope.enable = true;
        gnupg.agent = {
          enable = true;
        };
        localsend = {
          enable = true;
          openFirewall = true;
        };
        appimage = {
          enable = true;
          binfmt = true;
          package = pkgs.appimage-run.override {
            extraPkgs = pkgs: [
              pkgs.icu
              pkgs.libxcrypt-legacy
              pkgs.python312
            ];
          };
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
              #park_cores = no;
              #pin_cores = yes;
            };
          };
        };
      };

      environment.systemPackages =
        (with pkgs; [
          unzip
          bubblewrap
          nixfmt-tree
          (writeShellScriptBin "gamescope-run" ''
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

            exec env LD_PRELOAD= ${pkgs.gamescope}/bin/gamescope \
              "''${gamescope_args[@]}" \
              -- env LD_PRELOAD="$LD_PRELOAD" "''${game_cmd[@]}"
          '')
          (writeShellScriptBin "no-hardened" ''
            exec ${bubblewrap}/bin/bwrap \
              --dev-bind / / \
              --bind /dev/null /etc/ld-nix.so.preload \
              -- "$@"
          '')
        ])
        ++ (with inputs.reshade.packages.${pkgs.stdenv.hostPlatform.system}; [
          reshade
          reshade-shaders-full
        ]);

      fonts.packages =
        with pkgs;
        [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
        ]
        ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };

  flake.nixosModules.portals = { pkgs, config, ... }: {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.common.default = "*";
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config.niri = {
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
      config.gnome = {
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  flake.nixosModules.nixSettings =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      nix = {
        package = pkgs.lixPackageSets.stable.lix;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operator"
          ];
          system-features = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
          ];

          auto-optimise-store = true;
          keep-derivations = true;
          keep-outputs = true;

          substituters = [
            "https://cache.puppygirls.net/main"
          ];
          trusted-public-keys = [
            "main:8CPTNnHIH/5Bte4K50QWVlPi2nZR2Q6H1BY75cgst80="
          ];
        };
        nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
        registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
        optimise = {
          automatic = true;
          dates = [ "weekly" ];
        };
      };

      nixpkgs.overlays = [
        (final: prev: {
          inherit (prev.lixPackageSets.stable)
            nixpkgs-review
            nix-eval-jobs
            nix-fast-build
            colmena
            ;
        })
      ];

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3";
        flake = "/home/$(whoami)/olympus-nixos";
      };
    };

  flake.nixosModules.powerLogging = { pkgs, ... }: {
    systemd.services.power-logging = {
      description = "Log CPU (RAPL) and GPU power draw to CSV";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScriptBin "power-logging" ''
          INTERVAL=60
          RAPL=/sys/class/powercap/intel-rapl:0/energy_uj
          STATE_DIR="''${STATE_DIRECTORY:-/var/lib/power-logging}"
          OUT="$STATE_DIR/power.csv"

          if [ ! -e "$RAPL" ]; then
            echo "power-logging: no RAPL energy counter found, not logging"
            exit 0
          fi

          if [ ! -f "$OUT" ]; then
            echo "timestamp,cpu_w,gpu_w" > "$OUT"
          fi

          prev=$(cat "$RAPL")
          while sleep "$INTERVAL"; do
            cur=$(cat "$RAPL")
            delta=$((cur - prev))
            if [ "$delta" -lt 0 ]; then
              delta=$((delta + 4294967296))
            fi
            prev=$cur

            mw=$((delta / INTERVAL / 1000))
            cpu_w="$((mw / 1000)).$(printf '%02d' $((mw % 1000 / 10)))"

            gpu_w=""
            if command -v nvidia-smi >/dev/null 2>&1; then
              gpu_w=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 || true)
            fi

            echo "$(date -u +%FT%TZ),''${cpu_w},''${gpu_w}" >> "$OUT"
          done
        ''}/bin/power-logging";
        StateDirectory = "power-logging";
        Restart = "on-failure";
        RestartSec = "30s";
        NoNewPrivileges = true;
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "power-cost" ''
        set -eu

        LOG="''${STATE_DIRECTORY:-/var/lib/power-logging}/power.csv"

        if [ "$#" -ne 1 ]; then
          echo "usage: power-cost <price-per-kWh>   e.g. power-cost 0.22" >&2
          exit 1
        fi

        case "$1" in
          ""|*[!.0-9]*)
            echo "power-cost: '$1' is not a valid price-per-kWh number" >&2
            exit 1
            ;;
        esac

        if [ ! -f "$LOG" ]; then
          echo "power-cost: no log at $LOG — is the power-logging service running?" >&2
          exit 1
        fi

        awk -F, -v rate="$1" '
          NR > 1 && $2 != "" {
            w += $2
            n++
            if ($3 != "") { gw += $3; gn++ }
          }
          END {
            if (n == 0) { print "power-cost: log has no samples yet" > "/dev/stderr"; exit 1 }
            cpu = w / n
            gpu = gn > 0 ? gw / gn : 0
            total = cpu + gpu
            kwh = total * 720 / 1000
            printf "avg power:   %.1f W (cpu %.1f W + gpu %.1f W)\n", total, cpu, gpu
            printf "kWh/month:   %.1f kWh\n", kwh
            printf "cost/month:  $%.2f (at $%s/kWh)\n", kwh * rate, rate
          }' "$LOG"
      '')
    ];
  };

  flake.nixosModules.nvidia = { config, pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        libva-utils
      ];
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      package =
        let
          base = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
        in
        base
        // {
          open = base.open.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ../../patches/nvidia-open-kernel-7.2.patch ];
          });
        };
      modesetting.enable = true;
    };
  };

  flake.nixosModules.finalMouseUdev = { config, ... }: {
    services.udev.extraRules = ''
      # Finalmouse ULX devices - USB access
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0100", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0101", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0102", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0103", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0104", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0111", MODE="0660", TAG+="uaccess"

      # Finalmouse ULX devices - HID access
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0100", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0101", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0102", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0104", MODE="0660", GROUP="input", TAG+="uaccess"

      # Finalmouse Centerpiece Pro devices - USB access
      SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", TAG+="uaccess"

      # Finalmouse Centerpiece Pro devices - HID access
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", GROUP="input", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0021", MODE="0660", GROUP="input", TAG+="uaccess"
    '';
  };
}
