{ inputs, pkgs, ... }:

{

  imports = [
    ./xwayland.nix
    ./noctalia.nix
    ];
  home.packages = [ pkgs.niri ];

  xdg.configFile = {
    "niri/config.kdl".source = ./niri.kdl;
    "noctalia/settings.json".force = true;
  };
  
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
}
