{ pkgs, ... }:

{
    imports = [
        ./modules/vim.nix
        ./modules/bash.nix
        ./modules/packages.nix
    ];
}
