{ self, ... }:
{
  flake.overlays.olympus =
    final: prev:
    let
      system = final.stdenv.hostPlatform.system;
    in
    {
      inherit (prev.lixPackageSets.stable) nix-eval-jobs;
      inherit (self.packages.${system})
        assets
        decky-lsfg-vk
        decky-helixsrmanager
        futo-notes
        greenlight
        moondeckbuddy
        otter-launcher
        pi-agent-modes
        proton-em
        puppygirls
        redis-libc-malloc
        steamos-plymouth
        vm-test
        xlm
        xodus-nexus
        ;
    };
}
