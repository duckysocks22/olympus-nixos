{ pkgs, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
  crafty-controller = pkgs.callPackage ./crafty-controller/crafty-pkg.nix { };
in
{
  environment.systemPackages = [
    greenlight
  ];
}
