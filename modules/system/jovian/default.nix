{ inputs, ... }:
{
  flake.nixosModules.jovian =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.jovian.nixosModules.default

        inputs.self.nixosModules.jovianPlasma
        inputs.self.nixosModules.jovianPlymouth
      ];

      jovian = {
        steam = {
          enable = true;
          autoStart = true;
          desktopSession = "plasma";
          user = "deck";
          environment.STEAM_EXTRA_COMPAT_TOOLS_PATHS =
            lib.makeSearchPathOutput "steamcompattool" ""
              config.programs.steam.extraCompatPackages;
        };

        decky-loader = {
          enable = true;
          user = "deck";
          package = pkgs.jovianPackages.decky-loader-prerelease;
        };

        devices.steamdeck = lib.mkIf (config.networking.hostName == "dionysus-nixos") {
          enable = true;
          autoUpdate = true;
        };

        devices.steammachine = lib.mkIf (config.networking.hostName == "ariadne-nixos") {
          enable = true;
          autoUpdate = true;
        };
      };

      systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
        description = "Create Steam CEF debugging file";
        serviceConfig = {
          Type = "oneshot";
          User = config.jovian.steam.user;
          ExecStart = "/bin/sh -c '[ -e ~/.steam/steam ] && { [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true; }; true'";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
