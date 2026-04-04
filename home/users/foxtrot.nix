{ inputs, self, pkgs, config, ... }:
{
  flake.homeConfigurations.foxtrot = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
    modules = [
      self.homeModules.functions
      self.homeModules.shell
      self.homeModules.git
      self.homeModules.qbittorrent
      self.homeModules.functions
      self.homeModules.social
      self.homeModules.easyeffects
      self.homeModules.niri
      self.homeModules.player
      self.homeModules.foxtrot
      self.homeModules.stylix
      self.homeModules.download
      self.homeModules.common
      self.homeModules.creation
      self.homeModules.browsers
      self.homeModules.launchers
      self.homeModules.nixvim
      self.homeModules.nixcord
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

    extraSpecialArgs = { inherit inputs self pkgs; };
  };

  flake.homeModules = {
    shell = import ../shell.nix;
    git = import ../git.nix;
    qbittorrent = import ../services/qbittorrent.nix;
    functions = import ../functions.nix;
    social = import ../programs/social.nix;
    easyeffects = import ../programs/easyeffects.nix;
    niri = import ../niri/niri.nix;
    player = import ../programs/player.nix;
    foxtrot = import ../users/foxtrot.nix;
    stylix = import ../stylix/stylix.nix;
    download = import ../programs/download.nix;
    common = import ../programs/common.nix;
    cursors = import ../niri/cursors.nix;
    creation = import ../programs/creation.nix;
    browsers = import ../programs/browsers.nix;
    launchers = import ../programs/launchers.nix;
    xwayland = import ../niri/xwayland.nix;
    nixvim = import ../programs/nixvim.nix;
    nixcord = import ../programs/nixcord.nix;
    noctalia = import ../niri/noctalia.nix;
  };
}
