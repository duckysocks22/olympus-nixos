{ inputs, pkgs, ... }:

{

  imports = [
    inputs.noctalia.homeModules.default
    ./xwayland.nix
    ];
  home.packages = [ pkgs.niri ];

  xdg.configFile = {
    "niri/config.kdl".source = ./niri.kdl;
    "niri/noctalia.kdl".source=./noctalia.kdl;
  };
  
  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
  };

  services.mako.enable = true;
  services.polkit-gnome.enable = true;
}
