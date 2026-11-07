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
        inputs.self.nixosModules.userWarnPatch
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
      ];

      home-manager = homeManagerCommon // {

        users.foxtrot = { config, ... }: {
          imports = [
            inputs.self.homeModules.functions
            inputs.self.homeModules.common
            inputs.self.homeModules.librewolf
            inputs.self.homeModules.launchers
            inputs.self.homeModules.social
            inputs.self.homeModules.creation
            inputs.self.homeModules.player
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.nixcord
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.stylix
            inputs.self.homeModules.kitty
            inputs.self.homeModules.niri
            inputs.self.homeModules.baseShell
            inputs.self.homeModules.direnv
            inputs.self.homeModules.fastfetch
            inputs.self.homeModules.fzf
            inputs.self.homeModules.ranger
            inputs.self.homeModules.ssh
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
}
