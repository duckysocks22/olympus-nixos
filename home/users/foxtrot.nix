{ inputs, ... }:
{
  flake.homeConfigurations.foxtrot = home-manager.lib.homeManagerConfiguration {
    modules = [
      self.homeModules.functions
      {
        home.username = "foxtrot";
        home.homeDirectory = "/home/foxtrot";
        home.stateVersion = "25.11";

        home = {
          sessionVariables = {
            SCREENDIR = "${config.xdg.dataHome}/screen";
            _JAVA_OPTIONS="-Djava.util.prefs.userRoot=${config.xdg.dataHome}/java";
            XDG_CONFIG_HOME = config.xdg.configHome;
            XDG_CACHE_HOME = config.xdg.cacheHome;
            XDG_DATA_HOME = config.xdg.dataHome;
            XDG_STATE_HOME = config.xdg.stateHome;
            _JAVA_AWT_WM_NONREPARENTING = 1;
          };
        };

        systemd.user.startServices = "sd-switch";

        home.activation.xdgPortalRestart = config.lib.dag.entryAfter ["writeBoundary"] ''
         run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
        '';
      }
    ];
  };
}
