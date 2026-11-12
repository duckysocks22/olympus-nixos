{ inputs, self, ... }:
{
  flake.nixosModules.server =
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
      imports = [ ];

      users.users.server = {
        isNormalUser = true;
        home = "/home/server";
        hashedPasswordFile = config.sops.secrets."users/server".path;
        #hashedPassword = "$y$j9T$mhMeT8T34.qP6U4wfXYzx1$lrjDaXBHYNS/aJFMxscZXTmYgSvhmPCHJsCipZubJF.";
        shell = pkgs.fish;

        extraGroups = [
          "audio"
          "cdrom"
          "dailout"
          "input"
          "networkmanager"
          "render"
          "video"
          "wheel"
        ];

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDv/PuSaDn5Dg+1Bghk9OfR52iIFf5TvCucODDZKrCcx server@aether-nixos"
        ];
      };

      programs.fish.enable = true;

      home-manager.users.server =
        {
          config,
          ...
        }:
        {
          imports = [
            # Shared home settings
            inputs.self.homeModules.homeCommon
          ];

          home = {
            username = "server";
            homeDirectory = nixosConfig.users.users.server.home;
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
