{ config, lib, stylix, inputs, pkgs, ... }:

{
  imports = [
    ../../programs/default.nix
    ../../git.nix
    ../../niri/default.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/nixvim.nix
    ../../programs/nixcord.nix
    ../../programs/easyeffects.nix
  ];

  home.username = "foxtrot";
  home.homeDirectory = "/home/foxtrot";

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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.activation.xdgPortalRestart = config.lib.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
  '';

  # Home-Manager Version
  home.stateVersion = "25.11";
}
