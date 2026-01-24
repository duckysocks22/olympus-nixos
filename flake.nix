{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.11";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      athena-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix

	  home-manager.nixosModules.home-manager
	  {
	    home-manager.useGlobalPkgs = true;
	    home-manager.useUserPackages = true;

	    home-manager.users.foxtrot = import ./home/core.nix;
	   }
        ];
      };
    };
  };
}
