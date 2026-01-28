{ config, lib, stylix, inputs, ... }:

{
  imports = [
    ../../programs/default.nix
    ../../git.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/nixvim.nix
  ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";


  # Home-Manager Version
  home.stateVersion = "25.11";
}
