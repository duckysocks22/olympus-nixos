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
        inputs.self.nixosModules.userWarnPatch
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
            inputs.self.homeModules.librewolf
            inputs.self.homeModules.player
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.stylix
            inputs.self.homeModules.kitty
            inputs.self.homeModules.baseShell
            inputs.self.homeModules.direnv
            inputs.self.homeModules.fastfetch
            inputs.self.homeModules.fzf
            inputs.self.homeModules.ranger
            inputs.self.homeModules.ssh
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
}
