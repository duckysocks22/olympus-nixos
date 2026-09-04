{ inputs, self, ... }: {
  flake.nixosModules.foxtrot = {
    imports = [ inputs.home-manager.flakeModules.home-manager ];
    users.users.foxtrot = {
      isNormalUser = true;
      home = "/home/foxtrot";
      hashedPassword = "$y$j9T$2hwNZDEGyC/9B2eXztvxA0$HBU2ahHjb1FVCQjGIBbAEoqJlBe1/yzCq/DdSIfyg36";
      extraGroups = = [
        "audio"
        "dailout"
        "input"
        "networkmanager"
        "wheel"
        "cdrom"
      ];
      shell = pkgs.zsh
    };

    homeConfigurations.foxtrot = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        self.homeModules.functions
        self.homeModules.common
        self.homeModules.browsers
        self.homeModules.download
        self.homeModules.launchers
        self.homeModules.nixvim
        {
          home = {
            username = "foxtrot";
            homeDirectory = "/home/foxtrot";
            sessionVariables = {
              SCREENDIR = "${config.xdg.dataHome}/screen";
              _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.dataHome}/java";
              XDG_CONFIG_HOME = config.xdg.configHome;
              XDG_CACHE_HOME = config.xdf.cacheHome;
              XDG_DATA_HOME = config.xdg.dataHome;
              XDG_STATE_HOME = config.xdg.stateHome;
              _JAVA_AWT_WM_NONREPARENTING = 1;
              stateVersion = "26.05";
            };
          };

          systemd.user.startServices = "sd-switch";

          home.activation.xdgPortalRestart = config.lib.dag.entryAfter [ "writeBoundary" ] ''
            if ${pkgs.systemd}/bin/systemctl --user is-active --quiet xdg-desktop-portal.service 2>/dev/null; then
              run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
            fi
          '';
        }
      ];
    };

    services.displayManager.sessionPackages = [ pkgs.niri ];
  };
}
