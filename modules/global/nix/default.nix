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
        "main:OiT7TySueZMWxt1dpP7/SVwyhOwWu4L11tm1QhT2Qd8="
      ];
    };
    nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
    registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
  };
}
