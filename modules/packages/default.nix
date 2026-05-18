{ pkgs, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
in
{
  environment.systemPackages = [
    greenlight
  ];
}
