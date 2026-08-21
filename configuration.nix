# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

let
  sddmTheme = pkgs.sddm-astronaut.overrideAttrs (oldAttrs: {
    installPhase = ''
      mkdir -p $out/share/sddm/themes/sddm-astronaut-theme
      cp -r $src/* $out/share/sddm/themes/sddm-astronaut-theme
      chmod -R u+w $out/share/sddm/themes/sddm-astronaut-theme
      cp -f ${./home/modules/labwc/nixos-wallpaper-blurred.png} $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/astronaut.png
      sed -i 's|^PartialBlur=.*|PartialBlur="false"|' $out/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf
      sed -i 's|^FullBlur=.*|FullBlur="false"|' $out/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf
      sed -i 's|^CropBackground=.*|CropBackground="true"|' $out/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf
    '';
  });
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./garbage-collector.nix
      ./nvidia.nix # GPU configuration (modesetting, power management)
      ./steam.nix
    ];

  # Enable Flakes and new command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Enable Magic SysRq keys for emergency recovery (e.g. Alt + SysRq/Print + K to kill hung VT)
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  networking.nftables.enable = true;

  networking.firewall = {
    trustedInterfaces = [ "incusbr0" ];
  };
  
  services.resolved.enable = true;

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # Set your time zone.
  time.timeZone = "UTC"; # Change to your preferred timezone, e.g. "Europe/Madrid", "America/New_York"

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Display Manager (SDDM) with Astronaut theme, blurred NixOS wallpaper and visible cursor on NVIDIA
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false; # Greeter in X11 for reliable cursor visibility on NVIDIA (labwc starts in native Wayland)
    theme = "sddm-astronaut-theme";
    extraPackages = [
      sddmTheme
      pkgs.nordic
      pkgs.kdePackages.qtsvg
      pkgs.kdePackages.qtdeclarative
    ];
    settings = {
      Theme = {
        CursorTheme = "Nordic-cursors";
        CursorSize = 24;
      };
    };
  };
  # Register labwc as an available session in SDDM
  services.displayManager.sessionPackages = [ pkgs.labwc ];

  # Configure keymap in X11 / Wayland
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "terminate:ctrl_alt_bksp";
  };

  # Configure console keymap
  console.keyMap = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable udisks2 service for USB auto-mounting
  services.udisks2.enable = true;

  # Enable UPower service for battery and power management
  services.upower.enable = true;

  # Enable XDG Desktop Portal for Wayland compositors (labwc)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "wlr" "gtk" ];
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable Bluetooth & AirPods Pro support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  hardware.bluetooth.settings.Policy.ReconnectAttempts = 0;

  # Virtualisation: Incus (Containers and VMs)
  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = "127.0.0.1:8443";
      };
    };
  };

  # Define a user account.
  users.users."user" = {
    isNormalUser = true;
    description = "Default User";
    extraGroups = [ "networkmanager" "wheel" "incus-admin" "vboxguest" "vboxsf" ];
  };

  security.sudo.extraRules = [
    {
      users = [ "user" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.localBinInPath = true;

  home-manager.sharedModules = [
    ({ osConfig, ... }: {
      home.stateVersion = osConfig.system.stateVersion;
    })
  ];

  home-manager.backupFileExtension = "backup";

  home-manager.users.user = import ./home/user.nix;
  home-manager.users.root = import ./home/root.nix;

  # PAM permission for hyprlock screen locker
  security.pam.services.hyprlock = {};

  # Install firefox and dconf.
  programs.firefox.enable = true;
  programs.dconf.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System-wide fonts (for SDDM, system apps and terminal)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    brave
    fastfetch
    labwc                    # So SDDM detects labwc Wayland session
    sddmTheme                # Astronaut theme for SDDM (with blurred NixOS wallpaper)
    nordic                   # Nordic cursors system-wide for SDDM / Wayland
    
    # Theme dependencies for SDDM
    kdePackages.qtsvg
    kdePackages.qtdeclarative
  ];

  environment.variables = {
    EDITOR = "vim";
  };

  # Enable support for un-packaged dynamic executables
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      glib
      glibc
      nss
      nspr
      atk
      at-spi2-atk
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      gtk3
      pango
      cairo
      alsa-lib
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      mesa
      libgbm
      libglvnd
      libxkbcommon
      wayland
      libdrm
      udev
    ];
  };

  system.stateVersion = "26.05";
}
