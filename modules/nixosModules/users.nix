{ inputs, self, ... }: {
  flake.nixosModules.foxtrot = { inputs, pkgs, ... }: {
    imports = [ 
      inputs.home-manager.nixosModules.home-manager 
    ];

    users.users.foxtrot = {
      isNormalUser = true;
      home = "/home/foxtrot";
      hashedPassword = "$y$j9T$2hwNZDEGyC/9B2eXztvxA0$HBU2ahHjb1FVCQjGIBbAEoqJlBe1/yzCq/DdSIfyg36";
      extraGroups = [
        "audio"
        "dailout"
        "input"
        "networkmanager"
        "wheel"
        "cdrom"
      ];
      shell = pkgs.zsh;
    };

    services.displayManager.sessionPackages = [ pkgs.niri ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    home-manager.users.foxtrot = { config, ... }: {
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
        inputs.self.homeModules.easyeffects
        inputs.self.homeModules.stylix
        inputs.self.homeModules.niri
        inputs.self.homeModules.shell
        inputs.self.homeModules.download
      ];

      home = {
        username = "foxtrot";
        homeDirectory = "/home/foxtrot";
        stateVersion = "26.05";
        sessionVariables = {
          SCREENDIR = "${config.xdg.dataHome}/screen";
          _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.dataHome}/java";
          XDG_CONFIG_HOME = config.xdg.configHome;
          XDG_CACHE_HOME = config.xdg.cacheHome;
          XDG_DATA_HOME = config.xdg.dataHome;
          XDG_STATE_HOME = config.xdg.stateHome;
        };
      };

      systemd.user.startServices = "sd-switch";

      home.activation.xdgPortalRestart = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet xdg-desktop-portal.service 2>/dev/null; then
          run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
        fi
      '';
    };
  };

  flake.nixosModules.deck = { inputs, pkgs, ... }: {
    imports = [ 
      inputs.home-manager-unstable.nixosModules.home-manager 
    ];

    users.users.deck = {
      isNormalUser = true;
      home = "/home/deck";
      hashedPassword = "$y$j9T$2hwNZDEGyC/9B2eXztvxA0$HBU2ahHjb1FVCQjGIBbAEoqJlBe1/yzCq/DdSIfyg36";
      extraGroups = [
        "audio"
        "input"
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {
      inputs = inputs // {
        nixpkgs = inputs.nixpkgs-unstable;
        nixvim = inputs.nixvim-unstable;
      };
      pkgs-unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    home-manager.users.deck = { config, ... }: {
      imports = [
        inputs.self.homeModules.functions
        inputs.self.homeModules.browsers
        inputs.self.homeModules.launchers
        inputs.self.homeModules.nixvim
        inputs.self.homeModules.shell
        inputs.self.homeModules.common
      ];

      home = {
        username = "deck";
        homeDirectory = "/home/deck";
        stateVersion = "26.05";
        sessionVariables = {
          SCREENDIR = "${config.xdg.dataHome}/screen";
          XDG_CONFIG_HOME = config.xdg.configHome;
          XDG_CACHE_HOME = config.xdg.cacheHome;
          XDG_DATA_HOME = config.xdg.dataHome;
          XDG_STATE_HOME = config.xdg.stateHome;
        };
      };

      systemd.user.startServices = "sd-switch";
    };
  };
}
