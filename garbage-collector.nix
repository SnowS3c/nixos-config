{ config, pkgs, ... }:

{
  # Automatic garbage collection for Nix store
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Automatic store optimization via hard links
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
