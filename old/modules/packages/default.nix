{ pkgs, config, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
  piped-backend = pkgs.callPackage ./piped-backend/default.nix { };
  hid-tmff2 = config.boot.kernelPackages.callPackage ./kernel/hid-tmff2.nix { };
  moondeck-buddy = pkgs.callPackage ./moondeckbuddy.nix { };
in
{
  environment.systemPackages = [
    greenlight
    moondeck-buddy
  ];

  boot.extraModulePackages = [
    #hid-tmff2
  ];
}
