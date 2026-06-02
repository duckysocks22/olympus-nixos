{ inputs, pkgs, ... }:

{

  imports = [
    ./xwayland.nix
    ./dmshell.nix
    ./cursors.nix
    ./swayidle.nix
    ];
  home.packages = [ pkgs.niri pkgs.dconf pkgs.slurp ];

  xdg.configFile = {
    "niri/config.kdl" = { source = ./niri.kdl; force = true; };
    "niri/dms/cursor.kdl" = { source = ./dms/cursor.kdl; force = true; };
    "niri/dms/binds.kdl" = { source = ./dms/binds.kdl; force = true; };
    #"noctalia/settings.json".force = true;
  };

  gtk = {
    enable = true;
    #theme = {
    #  name = "Adwaita-dark";
    #  package = pkgs.gnome-themes-extra;
    #};
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
  
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
}
