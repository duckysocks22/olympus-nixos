{ inputs, self, ... }: {
  flake.nixosModules.jovian =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.jovian.nixosModules.default ];

      jovian = {
        steam = {
          enable = true;
          autoStart = true;
          desktopSession = "plasmax11";
          user = "deck";
          environment.STEAM_EXTRA_COMPAT_TOOLS_PATHS =
            lib.makeSearchPathOutput "steamcompattool" ""
              config.programs.steam.extraCompatPackages;
        };
        devices.steamdeck = {
          enable = true;
          autoUpdate = true;
        };
        decky-loader = {
          enable = true;
          user = "deck";
          package = pkgs.decky-loader-prerelease;
        };
      };

      # Create Steam CEF debugging file if it doesn't exist for Decky Loader.
      systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
        description = "Create Steam CEF debugging file";
        serviceConfig = {
          Type = "oneshot";
          User = config.jovian.steam.user;
          ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
        };
        wantedBy = [ "multi-user.target" ];
      };

      services = {
        desktopManager.plasma6.enable = true;
        xserver.enable = true;
      };

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        plasma-browser-integration
        konsole
        elisa
      ];

      programs.steam = {
        enable = true;
      };

      boot.plymouth = {
        enable = true;
        theme = lib.mkForce "steamos";
        themePackages = [
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steamos-plymouth
        ];
      };
    };
}
