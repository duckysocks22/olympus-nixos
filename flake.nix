{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOs/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager-unstable.url = "github:nix-community/home-manager";
    nix-index-database.url = "github:nix-community/nix-index-database";
    sops-nix.url = "github:Mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    preservation.url = "github:nix-community/preservation";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:FlameFlag/nixcord";
    };
    luxxy-pkgs = {
      url = "github:reedrw/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
