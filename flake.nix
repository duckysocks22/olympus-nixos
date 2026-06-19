{
  description = "Flake for 'Olympus' home network";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elysia = {
      url = "git+https://dawn.wine/foxtrottt/elysia-on-nix.git";
    };
    agl = {
      url = "github:an-anime-team/anime-games-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    px7-radio-git = {
      url = "git+https://dawn.wine/foxtrottt/px7-radio-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
    };
    nixcord = {
      url = "github:FlameFlag/nixcord";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    luxxy-pkgs = {
      url = "github:reedrw/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    netwatch = {
      url = "github:matthart1983/netwatch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    preservation = {
      url = "github:nix-community/preservation";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, sops-nix, disko, preservation, jovian, ... }: 
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
	    ./modules/global/stylix/stylix.nix
	    ./modules/global/lix.nix
	    disko.nixosModules.disko
            preservation.nixosModules.default
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
	    ./modules/global/stylix/stylix.nix
	    ./modules/global/lix.nix
            disko.nixosModules.disko
            preservation.nixosModules.default
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
            ./modules/global/stylix/stylix.nix
            ./modules/global/lix.nix
            jovian.nixosModules.default
            disko.nixosModules.disko
        ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
        nyx-nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/nyx/configuration.nix
            ./modules/global/stylix/stylix.nix
            ./home/default.nix
            ./modules/global/lix.nix

            {
              nixpkgs.overlays = [
                (import ./modules/overlays/caddy.nix)
                (import ./modules/overlays/ffmpeg-tdarr.nix)
              ];
            }
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
        olympus-iso = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/olympus-iso/configuration.nix
	    ./home/default.nix
	    ./modules/global/stylix/stylix.nix
	    ./modules/global/lix.nix
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-unstable;
          };
        };
    };
  };
}
