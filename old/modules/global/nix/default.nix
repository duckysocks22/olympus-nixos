{
  inputs,
  lib,
  config,
  ...
}:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
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
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "/home/$(whoami)/olympus-nixos";
  };
}
