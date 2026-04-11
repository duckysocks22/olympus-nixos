{ pkgs, ...}:
let
  dwproton = pkgs.callPackage ../packages/dwproton.nix { };
in
{
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton
    ];
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
