{ pkgs, ... }:

{
  # ═══════════════════════════════════════════════════════════
  # NATIVE PACKAGES AND TOOLS
  # ═══════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # Compositor and Wayland core
    labwc
    wlr-randr
    wl-clipboard
    wtype
    wlrctl

    # Taskbar, Launcher & Utilities
    waybar
    wofi
    cliphist
    flameshot

    # Wallpaper
    swaybg

    # Screen lock and idle management
    hyprlock
    hypridle

    # Notifications
    swaynotificationcenter
    libnotify

    # Screenshots (Grim / Slurp backend)
    grim
    slurp
    imagemagick

    # Terminal
    foot

    # File manager
    thunar
    thunar-volman

    # Standard Alternatives Wrappers
    (pkgs.writeShellScriptBin "x-terminal-emulator" ''exec ${pkgs.foot}/bin/foot "$@"'')
    (pkgs.writeShellScriptBin "x-www-browser" ''exec brave "$@"'')
    (pkgs.writeShellScriptBin "x-file-manager" ''exec ${pkgs.thunar}/bin/thunar "$@"'')
    (pkgs.writeShellScriptBin "editor" ''exec vim "$@"'')
    (pkgs.writeShellScriptBin "x-text-editor" ''exec ${pkgs.foot}/bin/foot -e vim "$@"'')

    # Audio and Brightness
    pavucontrol
    brightnessctl
    playerctl

    # Network, Bluetooth, Display and GUI Configuration
    networkmanagerapplet
    blueman
    wdisplays
    kanshi
    lxqt.obconf-qt
    nwg-look
    yad

    # Gaming
    mangohud
    gamemode

    # Icon fonts for Quickshell/Waybar and system
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only

    # Icon and GTK themes (available for nwg-look customization)
    papirus-icon-theme
    tela-circle-icon-theme
    tokyonight-gtk-theme
    catppuccin-gtk
    nordic
    gruvbox-gtk-theme
    bibata-cursors

    # System utilities
    btop
    lm_sensors
    ddcutil
  ];

  # Bluetooth AVRCP / MPRIS Proxy daemon (AirPods / Media controls)
  services.mpris-proxy.enable = true;

  # GTK icon theme configuration
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Mouse cursor theme configuration (Nordic-cursors)
  home.pointerCursor = {
    name = "Nordic-cursors";
    package = pkgs.nordic;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Enable fontconfig to recognize user fonts
  fonts.fontconfig.enable = true;

  # USB auto-mounting service (udiskie) with system tray icon
  services.udiskie = {
    enable = true;
    tray = "auto";
  };
  systemd.user.services.udiskie.Install.WantedBy = pkgs.lib.mkForce [ "default.target" ];

  # Notification daemon service (SwayNC)
  services.swaync.enable = true;

  # Display management service (Kanshi) — Set 165Hz on primary display
  services.kanshi = {
    enable = true;
    systemdTarget = "";
    settings = [
      {
        profile = {
          name = "desktop";
          outputs = [
            {
              criteria = "DP-3";
              mode = "1920x1080@60Hz";
              position = "0,0";
              scale = 1.0;
            }
          ];
        };
      }
    ];
  };

  # ═══════════════════════════════════════════════════════════
  # LINKS TO EXTERNAL CONFIGURATION FILES
  # ═══════════════════════════════════════════════════════════

  xdg.configFile = {
    # ── labwc ──
    "labwc/rc.xml".source = ./labwc/rc.xml;
    "labwc/menu.xml".source = ./labwc/menu.xml;
    "labwc/nixos-wallpaper.png".source = ./labwc/nixos-wallpaper.png;
    "labwc/autostart" = {
      executable = true;
      source = ./labwc/autostart;
    };
    "labwc/environment".source = ./labwc/environment;
    "labwc/themerc-override".source = ./labwc/themerc-override;
    "labwc/scripts".source = ./labwc/scripts;

    # ── Terminal ──
    "foot/foot.ini".source = ./labwc/foot.ini;

    # ── Taskbar (Waybar) & Launcher (Wofi) ──
    "waybar/config".source = ./labwc/waybar-config.json;
    "waybar/style.css".source = ./labwc/waybar-style.css;
    "wofi/config".source = ./labwc/wofi-config;
    "wofi/style.css".source = ./labwc/wofi-style.css;

    # ── Screenshots (Flameshot) ──
    "flameshot/flameshot.ini".source = ./labwc/flameshot.ini;

    # ── Notifications ──
    "swaync/config.json".source = pkgs.lib.mkForce ./labwc/swaync-config.json;
    "swaync/style.css".source = pkgs.lib.mkForce ./labwc/swaync-style.css;

    # ── Screen locking ──
    "hypr/hyprlock.conf".source = ./labwc/hyprlock.conf;
    "hypr/hypridle.conf".source = ./labwc/hypridle.conf;
  };

  # ═══════════════════════════════════════════════════════════
  # DESKTOP ENTRIES FOR APPLICATIONS
  # ═══════════════════════════════════════════════════════════

  xdg.desktopEntries.antigravity-ide = {
    name = "Antigravity IDE";
    genericName = "Code Editor / IDE";
    exec = "antigravity-ide %F";
    icon = "/opt/Antigravity IDE/resources/app/resources/linux/code.png";
    terminal = false;
    categories = [ "Development" "IDE" "TextEditor" ];
    comment = "Antigravity AI Code Editor";
    settings = {
      StartupWMClass = "antigravity-ide";
    };
  };
}

