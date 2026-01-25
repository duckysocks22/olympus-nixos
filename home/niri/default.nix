{ inputs, pkgs, ... }:

{

  imports = [
    ./xwayland.nix
    ./noctalia.nix
    ./cursors.nix
    ];
  home.packages = [ pkgs.niri pkgs.dconf ];

  xdg.configFile = {
    "niri/config.kdl".source = ./niri.kdl;
    "noctalia/settings.json".force = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
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
