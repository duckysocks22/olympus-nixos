{ config, lib, stylix, inputs, ... }:

{
  imports = [
    ../../git.nix
    ../../shell.nix
  ];

  home.username = "foxtrot";
  home.homeDirectory = "/home/foxtrot";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";


  # Home-Manager Version
  home.stateVersion = "25.11";
}
