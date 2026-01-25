{ inputs, pkgs-unstable, ...}:
{

      imports = [ inputs.home-manager.nixosModules.home-manager ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {
        inherit inputs;
	inherit pkgs-unstable;
      };

      home-manager.users.foxtrot = import ./users/foxtrot/core.nix;
}
