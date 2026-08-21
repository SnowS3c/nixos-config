{ config, lib, pkgs, ... }:

{
  # Nvidia drivers and graphics require allowUnfree

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;

    # Override to version 610.57.04
    # https://nixos.wiki/wiki/Nvidia
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "610.57.04";
      
      # Hash of the official x86_64 installer (.run)
      sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
          
      # Hash for open-source kernel modules (open = true)
      openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
      settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
      persistencedSha256 = lib.fakeSha256; # Replace with the real hash or set to "" if not needed
    };
  };
}
