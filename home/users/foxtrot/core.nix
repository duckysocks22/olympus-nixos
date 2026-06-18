{ config, lib, stylix, inputs, pkgs, ... }:

{
  imports = [
    ../../programs/default.nix
    ../../programs/claude-code.nix
    ../../git.nix
    ../../niri/default.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/nixvim.nix
    ../../programs/nixcord.nix
    ../../programs/easyeffects.nix
    ../../programs/download.nix
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
    # Guard against running during system activation when the user session
    # isn't up yet — systemctl --user will fail if there is no D-Bus session.
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet xdg-desktop-portal.service 2>/dev/null; then
      run ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service
    fi
  '';

  # Home-Manager Version
  home.stateVersion = "26.05";
}
