{ inputs, self, ... }:
let
  homeManagerCommon = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };
  };

  mkSessionVariables = config: {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SCREENDIR = "${config.xdg.dataHome}/screen";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.dataHome}/java";
    XDG_CONFIG_HOME = config.xdg.configHome;
    XDG_CACHE_HOME = config.xdg.cacheHome;
    XDG_DATA_HOME = config.xdg.dataHome;
    XDG_STATE_HOME = config.xdg.stateHome;
  };
in
{
  flake.nixosModules.foxtrot =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      users.users.foxtrot = {
        isNormalUser = true;
        home = "/home/foxtrot";
        hashedPasswordFile = config.sops.secrets."users/foxtrot".path;
        initialHashedPassword = "$y$j9T$EOxAFD9l0qIXDVJ1XGG7P0$OhvzNuUJXJB2TWRShPxz6Z6KkpMQvB2dqnOETQHQae5";
        extraGroups = [
          "audio"
          "dailout"
          "input"
          "networkmanager"
          "wheel"
          "cdrom"
          "libvirtd"
        ];
        shell = pkgs.fish;
      };

      programs.fish.enable = true;

      services.displayManager.sessionPackages = [
        pkgs.niri
        inputs.doors.packages.${pkgs.stdenv.hostPlatform.system}.doors
      ];

      home-manager = homeManagerCommon // {

        users.foxtrot = { config, ... }: {
          imports = [
            inputs.self.homeModules.functions
            inputs.self.homeModules.common
            inputs.self.homeModules.browsers
            inputs.self.homeModules.launchers
            inputs.self.homeModules.social
            inputs.self.homeModules.creation
            inputs.self.homeModules.player
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.nixcord
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.stylix
            inputs.self.homeModules.niri
            inputs.self.homeModules.doors
            inputs.self.homeModules.shell
            inputs.self.homeModules.foxtrotSops
            inputs.self.homeModules.syncthing
          ];

          home = {
            username = "foxtrot";
            homeDirectory = "/home/foxtrot";
            stateVersion = "26.05";
            sessionVariables = mkSessionVariables config;
          };

          systemd.user.startServices = "sd-switch";

          home.activation.xdgPortalRestart = config.lib.dag.entryAfter [ "writeBoundary" ] ''
            if ${pkgs.systemd}/bin/systemctl --user is-active --quiet xdg-desktop-portal.service 2>/dev/null; then
              run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
            fi
          '';
        };
      };
    };

  flake.nixosModules.server =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      users.users.server = {
        isNormalUser = true;
        home = "/home/server";
        hashedPasswordFile = config.sops.secrets."users/server".path;
        initialHashedPassword = "$y$j9T$EOxAFD9l0qIXDVJ1XGG7P0$OhvzNuUJXJB2TWRShPxz6Z6KkpMQvB2dqnOETQHQae5";
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "wheel"
          "video"
          "render"
          "cdrom"
        ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDv/PuSaDn5Dg+1Bghk9OfR52iIFf5TvCucODDZKrCcx server@nixos"
        ];
      };

      programs.fish.enable = true;

      users.users.share = {
        description = "Write-access to samba media shares";
        group = "share";
        extraGroups = [ "users" ];
        hashedPasswordFile = config.sops.secrets."users/server".path;
        isSystemUser = true;
      };

      users.groups.share = { };

      home-manager = homeManagerCommon // {

        users.server = { config, ... }: {
          imports = [
            inputs.self.homeModules.functions
            inputs.self.homeModules.common
            inputs.self.homeModules.browsers
            inputs.self.homeModules.player
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.stylix
            inputs.self.homeModules.shell
            inputs.self.homeModules.serverSops
          ];

          home = {
            username = "server";
            homeDirectory = "/home/server";
            stateVersion = "26.05";
            sessionVariables = mkSessionVariables config;
          };
          systemd.user.startServices = "sd-switch";
        };
      };

      security.sudo.extraRules = [
        {
          users = [ "server" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

  flake.nixosModules.deck =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      imports = [
        inputs.home-manager-unstable.nixosModules.home-manager
      ];

      users.users.deck = {
        isNormalUser = true;
        home = "/home/deck";
        hashedPasswordFile = config.sops.secrets."users/deck".path;
        initialHashedPassword = "$y$j9T$EOxAFD9l0qIXDVJ1XGG7P0$OhvzNuUJXJB2TWRShPxz6Z6KkpMQvB2dqnOETQHQae5";
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDv/PuSaDn5Dg+1Bghk9OfR52iIFf5TvCucODDZKrCcx server@nixos"
        ];
      };

      programs.fish.enable = true;

      home-manager = homeManagerCommon // {
        extraSpecialArgs = {
          inputs = inputs // {
            nixpkgs = inputs.nixpkgs-unstable;
            nixvim = inputs.nixvim-unstable;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            localSystem = "x86_64-linux";
            config.allowUnfree = true;
          };
        };

        users.deck = { config, ... }: {
          imports = [
            inputs.self.homeModules.functions
            inputs.self.homeModules.browsers
            inputs.self.homeModules.launchers
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.shell
            inputs.self.homeModules.common
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.deckSops
            inputs.self.homeModules.syncthing
          ];

          home.file = {
            ".local/bin/com.discordapp.Discord" = {
              source = pkgs.writeShellScript "com.discordapp.Discord" ''
                unset LD_LIBRARY_PATH
                unset LD_PRELOAD
                exec ${pkgs.discord}/bin/discord "$@"
              '';
              force = true;
            };
            ".local/share/applications/com.discordapp.Discord.desktop" = {
              source = pkgs.writeText "com.discordapp.Discord.desktop" ''
                [Desktop Entry]
                Name=Discord
                Comment=All-in-one voice and text chat for gamers
                Exec=${config.home.homeDirectory}/.local/bin/com.discordapp.Discord
                Icon=discord
                Terminal=false
                Type=Application
                Categories=Network;InstantMessaging;
              '';
              force = true;
            };
          };

          systemd.user.services.discord-autostart = {
            Unit = {
              Description = "Discord (background) for Steam Big Picture";
              After = [ "gamescope-session.service" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "exec";
              EnvironmentFile = "-%t/gamescope-environment";
              ExecStart = "${config.home.homeDirectory}/.local/bin/com.discordapp.Discord";
              Restart = "on-failure";
              RestartSec = 10;
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };

          home = {
            username = "deck";
            homeDirectory = "/home/deck";
            stateVersion = "26.05";
            sessionVariables = mkSessionVariables config;
          };

          systemd.user.startServices = "sd-switch";
        };
      };
    };
}
