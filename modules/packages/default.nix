{ pkgs, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
  crafty-controller = pkgs.callPackage ./crafty-controller.nix { };
in
{
  environment.systemPackages = [
    greenlight
  ];
}
