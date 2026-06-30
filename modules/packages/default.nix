{ pkgs, config, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
  piped-backend = pkgs.callPackage ./piped-backend/default.nix { };
  hid-tmff2 = config.boot.kernelPackages.callPackage ./kernel/hid-tmff2.nix { };
in
{
  environment.systemPackages = [
    greenlight
    piped-backend
  ];

  boot.extraModulePackages = [
    #hid-tmff2
  ];
}
