{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elysia = {
      url = "git+https://dawn.wine/foxtrottt/elysia-on-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ... }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in {
      nixosConfigurations = {
        athena-nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/athena/configuration.nix
	    ./home/default.nix
          ];
	  specialArgs = { 
	    inherit inputs; 
            inherit pkgs-unstable;
	  };
        };
        circe-nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/circe/configuration.nix
	    ./home/default.nix
          ];
	  specialArgs = { 
	    inherit inputs; 
	    inherit pkgs-unstable; 
	  };
        };
      };
    };
}
