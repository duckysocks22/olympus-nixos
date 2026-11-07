{ inputs, self, ... }:
{
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
            AutoEnable = lib.mkDefault true;
          };
        };
      };

      services = {
        tuned.enable = true;
        upower.enable = true;
        gnome.gnome-keyring.enable = true;
        xserver.xkb = {
          layout = "us";
          variant = "";
        };
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

      time.timeZone = "America/New_York";

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
              "athena-nixos" = pkgs.linuxPackages_latest;
              "circe-nixos" = pkgs.linuxPackages_latest;
            };
          in
          kernel.${config.networking.hostName} or (
            if config ? jovian then
              pkgs.jovianPackages.linuxPackages
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
}
