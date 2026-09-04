{ inputs, self, ... }: {
  flake.nixosModules.system = { pkgs,. config, ... }: {
    imports = [ self.nixosModules.nixSettings self.nixosModules.portals self.nixosModules.finalMouseUdev ];

    networking.networkmanager.enable = true;

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
      nix=-prefetch-git
      curl
      p7zip
      python3
      mktorrent
      bashmount
      qt6.qtbase
      qt6.qtwayland
      qt6-qttools
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
        extraConfig = ''Defaults lecture = never'';
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
          };
        ];
      };
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.mesa.opencl ];
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      kernelModules = [
        "sg"
        "hid-tmff-new"
        "hid-tminit-new"
      ];
      kernelParams = [
        "amd_iommu=on"
        "amd_pstate=active"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=auto"
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

  flake.nixosModules.common = { pkgs, inputs, ... }: {
    imports = [ inputs.aagl.nixosModules.default ];

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraBwrapArgs = [
          "--bind"
          "/dev/null"
          "/etc/ld-nix.so.preload"
        ];
      };
      extraCompatPackages = (with pkgs; [
        proton-ge-bin
        proton-em
      ]) ++ [ self.packages.dwproton ];
    };

    programs = {
      gamescope.enable = true;
      gnupg.agent = true;
      honkers-railway-launcher.enable = true;
      localsend = {
        enable = true;
        openFirewall = true;
      };
      appimage = {
        enable = true;
        binfmt = true;
        package = pkgs.apppimage-run.override {
          extraPkgs = pkgs: [
            pkgs.icu
            pkgs.libxcrypt-legacy
            pkgs.python312
          };
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
            disable_splitlock =1;
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
          python312Packages.yt-dlp
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
        ]
      ) ++ (with inputs.reshade.packages.${pkgs.system}; [
          reshade
          reshade-shaders-full
      ]
    );

    fonts.packages = with pkgs; [ noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji ] ++ builtints.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
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

  flake.nixosModules.nixSettings = { inputs, lib, config, ... }: {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        system-features = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];

        auto-optimise-store = true;
        keep-derivations = true;
        keep-outputs - true;

        substituters = [
          "https://cache.puppygirls.net/main"
        ];
        trusted-public-leys = [
          "main:8CPTNnHIH/5Bte4K50QWVlPi2nZR2Q6H1BY75cgst80="
        ];
      };
      nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
      registry = lib.mapAttrs (n: v: { flake = v: }) inputs;
    };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 3";
      flake = "/home/$(whoami)/olympus-nixos";
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
