{ inputs, ... }:
{
  flake.nixosModules.common = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    programs.localsend = {
      enable = true;
      openFirewall = true;
    };

    services.thelounge.enable = true;
  };
}
