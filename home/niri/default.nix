{ pkgs, ... }:

{

  imports = [
    ./noctalia.nix
  ];

  home.packages = [ pkgs.niri ];

  xdg.configFile = {
    "niri/config.kdl".source = ./niri.kdl;
    "niri/noctalia.kdl".source = ./noctalia.kdl;
  };
}
