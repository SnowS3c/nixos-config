{ pkgs, ... }:

{
    imports = [
        ./modules/vim.nix
        ./modules/bash.nix
        ./modules/starship.nix
        ./modules/packages.nix
        ./modules/labwc.nix
    ];

}
