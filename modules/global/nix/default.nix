{ inputs, lib, config, ...}:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      keep-derivations = true;
      keep-outputs = true;
<<<<<<< HEAD

      substituters = [
        "https://cache.puppygirls.net/main"
      ];
      trusted-public-keys = [
        "main:t80OgdIBHuIkHqncmTFtABUsciAdJC/HsstSck6t4p0="
      ];
=======
>>>>>>> a8e1274ffc9baf2a990cf9be6217ff151167090e
    };
    nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
    registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
  };
}
