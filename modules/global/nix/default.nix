{ inputs, lib, config, ...}:
let
  homeIP = builtins.readFile "${config.sops.secrets."home/public-ip".path}";
in
{
  nix = {
    settings = {
      auto-optimise-store = true;
      keep-derivations = true;
      keep-outputs = true;
      
      substituters = [
        "${homeIP}"
      ];
      trusted-public-keys = [
        "main:eX21fIMCHYo3MNbT6xDD7Xy45FcNAP/P97Vs2vdH0Ek="
      ];
    };
    nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
    registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
  };
}
