{ config, lib, stylix, inputs, ... }:

{
  imports = [
    ../../git.nix
    ../../shell.nix
    ../../stylix/stylix.nix
    ../../programs/common.nix
    ../../programs/nixvim.nix
    ../../functions.nix
    ../../services/qbittorrent.nix
  ];

  home.username = "server";
  home.homeDirectory = "/home/server";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";


  # Home-Manager Version
  home.stateVersion = "25.11";
}
