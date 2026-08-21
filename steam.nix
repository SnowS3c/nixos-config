{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud # Available for metrics if 'mangohud' is added to Launch Options
  ];

  # Recommended Steam configuration:
  # In game properties -> Launch Options:
  #   gamemoderun %command%
  #
  # If you want to view the metrics overlay (MangoHud) for a specific game:
  #   mangohud gamemoderun %command%
}
