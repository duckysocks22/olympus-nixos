{ inputs, self, ... }:
{
  flake.nixosModules.steam =
    {
      config,
      pkgs,
      pkgs-unstable,
      inputs,
      lib,
      ...
    }:
    {
      programs = {
        steam = {
          enable = true;
          package = lib.mkIf (!(config ? jovian)) (
            pkgs.steam.override {
              extraProfile = ''
                export LD_LIBRARY_PATH=${
                  lib.makeLibraryPath [ pkgs.sdl2-compat ]
                }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
              '';
              extraBwrapArgs = [
                "--bind"
                "/dev/null"
                "/etc/ld-nix.so.preload"
              ];
            }
          );
          extraCompatPackages =
            (with pkgs; [
              proton-ge-bin
            ])
            ++ [
              inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dwproton
              inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.proton-em
              inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.xlm
            ];
        };
      };
    };
}
