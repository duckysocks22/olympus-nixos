{ inputs, self, ... }:
{
  flake.nixosModules.system =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        git
        wget
        vim
        gptfdisk
        gparted
        xfsprogs
        cifs-utils
        nix-prefetch-git
        curl
        p7zip
        python3
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
        lixPackageSets.stable.colmena
      ];

      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings/schemas/${pkgs.gtk3.name}"
      ];

      time.timeZone = "America/New_York";

      nixpkgs = {
        config.allowUnfree = true;
        overlays = [
          inputs.self.overlays.olympus
        ];
      };

      services = {
        pulseaudio.enable = false;
        libinput.enable = true;
        xserver.xkb = {
          layout = "us";
          variant = "";
        };

        pipewire = {
          enable = true;
          pulse.enable = true;

          alsa = {
            enable = true;
            support32Bit = true;
          };
        };

        logind.settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
        };
      };

      users.mutableUsers = false;

      security = {
        rtkit.enable = true;
        polkit.enable = true;
        protectKernelImage = false;

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
              ];
            }
          ];
        };
      };

      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "1h";
        HibernateMode = "shutdown";
      };

      boot = {
        kernelPackages = (
          if config ? jovian && config.jovian.steam.enable then
            pkgs.jovianPackages.linuxPackages
          else
            pkgs.linuxPackages_latest
        );

        kernelModules = [
          "sg"
        ];

        kernelParams = [
          "quiet"
          "splash"
        ];
      };

      nix = {
        package = pkgs.lixPackageSets.stable.lix;
        nixPath = lib.mapAttrsToList (n: v: "${n}flake:${n}") inputs;
        registry = lib.mapAttrs (n: v: { flake = v; }) inputs;

        optimise = {
          automatic = true;
          dates = [ "weekly" ];
        };

        settings = {
          auto-optimise-store = true;
          keep-derivations = true;
          keep-outputs = true;

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
            "pipe-operators"
          ];

          substituters = [
            "https://cache.puppygirls.net/main"
          ];

          trusted-public-keys = [
            "main:8CPTNnHIH/5Bte4K50QWVlPi2nZR2Q6H1BY75cgst80="
          ];
        };
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3";
        flake = "/home/$(whoami)/olympus-nixos}";
      };
    };
}
