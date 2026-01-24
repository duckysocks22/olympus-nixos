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
          ./hosts/athena/configuration.nix

	  home-manager.nixosModules.home-manager
	  ./home/default.nix
        ];
      };
      circe-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/circe/configuration.nix

	  home-manager.nixosModules.home-manager
	  ./home/default.nix
        ];
      };
    };
  };
}
