{ pkgs, inputs, ...}:
let
  dwproton = pkgs.callPackage ../packages/dwproton.nix { };
in
{

  imports = [
    inputs.aagl.nixosModules.default
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton
    ];
  };

  programs.honkers-railway-launcher.enable = true;

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Fonts
  environment.systemPackages = with pkgs; [
    nerd-fonts.dejavu-sans-mono
  ];
}
