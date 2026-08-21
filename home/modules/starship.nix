{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  # Symlinks the configuration file to ~/.config/starship.toml
  xdg.configFile."starship.toml".source = ./starship.toml;
}
