{ pkgs, ... }:
let
  greenlight = pkgs.callPackage ./greenlight.nix { };
  piped-backend = pkgs.callPackage ./piped-backend/default.nix { };
in
{
  environment.systemPackages = [
    greenlight
    piped-backend
  ];
}
