{ inputs, self, ... }:
{
  flake.nixosModules.userWarnPatch =
    { modulesPath, ... }:
    let
      configDir = modulesPath + "/config";
      upstream = builtins.readFile (configDir + "/users-groups.nix");
      patched =
        builtins.replaceStrings
          [
            "1 >= length (filter (x: x != null) (map (flip getAttr user) passwordOptions))"
            "./update-users-groups.pl"
          ]
          [
            ''
              let
                countSet = opts: builtins.length (builtins.filter (x: user.''${x} != null) opts);
                isInitial =
                  x: lib.hasPrefix "initial" x || (!cfg.mutableUsers && x == "hashedPassword");
              in
              countSet (builtins.filter isInitial passwordOptions) <= 1
              && countSet (builtins.filter (x: !isInitial x) passwordOptions) <= 1
            ''
            (toString (configDir + "/update-users-groups.pl"))
          ]
          upstream;
    in
    {
      disabledModules = [ "config/users-groups.nix" ];
      imports = [ (import (builtins.toFile "users-groups.nix" patched)) ];
    };
}
