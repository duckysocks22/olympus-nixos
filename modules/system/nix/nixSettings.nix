{ inputs, self, ... }:
{
  flake.nixosModules.nixSettings =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      nix = {
        package = pkgs.lixPackageSets.stable.lix;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operator"
          ];
          system-features = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
            "pipe-operators"
          ];

          auto-optimise-store = true;
          keep-derivations = true;
          keep-outputs = true;

          substituters = [
            "https://cache.puppygirls.net/main"
          ];
          trusted-public-keys = [
            "main:8CPTNnHIH/5Bte4K50QWVlPi2nZR2Q6H1BY75cgst80="
          ];
        };
        nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
        registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
        optimise = {
          automatic = true;
          dates = [ "weekly" ];
        };
      };

      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
        (final: prev: {
          inherit (prev.lixPackageSets.stable)
            nixpkgs-review
            nix-eval-jobs
            nix-fast-build
            colmena
            ;
        })
      ];

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3";
        flake = "/home/$(whoami)/olympus-nixos";
      };
    };
}
