{ config, lib, inputs, ... }:

{
  imports = [
    ../../programs/default-deck.nix
    ../../git.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/nixvim.nix
    ../../programs/common.nix
  ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";


  # Home-Manager Version
  home.stateVersion = "26.05";
}
