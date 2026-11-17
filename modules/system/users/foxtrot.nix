{ inputs, self, ... }:
{
  flake.nixosModules.foxtrot =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    let
      nixosConfig = config;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.self.nixosModules.homeManagerCommon
      ];

      users.users.foxtrot = {
        isNormalUser = true;
        home = "/home/foxtrot";
        hashedPasswordFile = config.sops.secrets."users/foxtrot".path;
        #hashedPassword = "$y$j9T$4GItUEhleK3nz0h/kp5IK.$0QU4bjxLjuAXL61ITBTA5r8HnqBg6x0ck./kA2rkkp8";

        shell = pkgs.fish;

        extraGroups = [
          "audio"
          "cdrom"
          "dailout"
          "input"
          "networkmanager"
          "wheel"
        ];
      };

      programs.fish.enable = true;

      services.displayManager.sessionPackages = [
        pkgs.niri
      ];

      home-manager.users.foxtrot =
        {
          config,
          ...
        }:
        {
          imports = [
            # Shared home settings
            inputs.self.homeModules.homeCommon

            # Functions
            inputs.self.homeModules.functions

            # Interface
            inputs.self.homeModules.niri

            # Shell
            inputs.self.homeModules.shell

            # Software
            inputs.self.homeModules.foxtrotSops
            inputs.self.homeModules.software
            inputs.self.homeModules.launchers
            inputs.self.homeModules.social
            inputs.self.homeModules.creation
            inputs.self.homeModules.player
            inputs.self.homeModules.librewolf
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.nixcord
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.syncthing

            # Theme
            inputs.self.homeModules.stylix
            inputs.self.homeModules.adwaita-for-steam

          ];

          home = {
            username = "foxtrot";
            homeDirectory = nixosConfig.users.users.foxtrot.home;
            stateVersion = nixosConfig.system.stateVersion;
          };

          systemd.user.startServices = "sd-switch";

          home.activation.xdgPortalRestart = config.lib.dag.entryAfter [ "writeBoundary" ] ''
            if ${pkgs.systemd}/bin/systemctl --user is-active --quiet xdg-desktop-portal.service 2>/dev/null; then
              run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
            fi
          '';
        };
    };
}
