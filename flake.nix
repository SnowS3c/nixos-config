{
  description = "Declarative NixOS + Home Manager + labwc configuration";

  inputs = {
    # Official NixOS 26.05 package repository
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Home Manager corresponding to release 26.05
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
  };
}
