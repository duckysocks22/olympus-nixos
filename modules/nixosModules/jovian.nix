{ inputs, self, ... }: {
  flake.nixosModules.jovian = { config, pkgs, lib, ... }: {
    imports = [ inputs.jovian.nixosModules.default ];

    jovian = {
      steam = {
        enable = true;
        autoStart = true;
        desktopSession = "plasmax11";
        user = "deck";
      };
      decky-loader = {
        enable = true;
      };
      devices.steamdeck = {
        enable = true;
        autoUpdate = true;
      };
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
        inputs.self.packages.${pkgs.system}.steamos-plymouth
      ];
    };
  };
}
