{ inputs, lib, ...}:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      keep-derivations = true;
      keep-outputs = true;
      
    };
    nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
    registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
  };
}
