{ inputs, ...}: {
    
    flake.nixosModules.nix-settings = { pkgs, lib, ... }: {
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "25.11";

      nix = {
        settings = {
          auto-optimise-store = true;
          keep-derivations = true;
          keep-outputs = true;
          experimental-features = [ "nix-command" "flakes" ];
        };
        nixPath = lib.mapAttrsToList (n: v: "${n}=flake:${n}") inputs;
        registry = lib.mapAttrs (n: v: { flake = v; }) inputs;
      };
    };
}
