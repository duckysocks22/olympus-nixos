{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    stress-ng
    y-cruncher
  ];
}
