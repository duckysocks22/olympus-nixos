{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elysia = {
      url = "git+https://dawn.wine/foxtrottt/elysia-on-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
    };
    nixcord = {
      url = "github:FlameFlag/nixcord";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, stylix, nixvim, sops-nix, ... }: 
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
	    ./modules/stylix/stylix.nix
	    ./modules/lix.nix
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
	    ./modules/stylix/stylix.nix
	    ./modules/lix.nix
          ];
	  specialArgs = { 
	    inherit inputs; 
	    inherit pkgs-unstable; 
	  };
        };
        dionysus-nixos = nixpkgs-unstable.lib.nixosSystem {
          modules = [
            ./hosts/dionysus/configuration.nix
            ./home/default-unstable.nix
            ./modules/stylix/stylix.nix
            ./modules/lix.nix
        ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
        nyx-nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/nyx/configuration.nix
            ./modules/stylix/stylix.nix
            ./home/default.nix
            ./modules/lix.nix
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
    };
  };
}
