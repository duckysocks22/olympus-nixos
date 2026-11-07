{ inputs, self, ... }:
{
  flake.nixosModules.retroarch = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      (retroarch.withCores (
        cores: with cores; [
          libretro.melondsds
          libretro.snes9x
          libretro.mupen64plus
          libretro.genesis-plus-gx
          libretro.swanstation
          libretro.citra
          libretro.ppsspp
        ]
      ))
    ];
  };
}
