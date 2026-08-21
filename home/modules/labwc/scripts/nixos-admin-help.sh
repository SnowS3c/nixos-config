#!/usr/bin/env bash

# NixOS & Flakes Administration Cheat Sheet Dialog using YAD

yad --list \
  --title="📖 NixOS & Flakes Administration Manual" \
  --window-icon="system-help" \
  --width=980 \
  --height=640 \
  --center \
  --search-column=2 \
  --column="Category":TEXT \
  --column="Command":TEXT \
  --column="Description / Action":TEXT \
  --button="Close:0" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild switch" "Apply changes immediately and add a new boot generation" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild test" "Test changes in memory temporarily (without adding to bootloader)" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild boot" "Build and register in bootloader for next reboot (do not switch now)" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild switch --rollback" "Instantly roll back to the previous working generation" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild dry-build" "Verify configuration syntax and build without downloading or installing" \
  "🔄 Rebuild & Deploy" "sudo nixos-rebuild switch --flake .#nixos" "Rebuild system using Flakes and pinned flake.lock dependencies" \
  "❄️ Flakes & Environments" "nix flake update" "Update all flake inputs and lock new versions in flake.lock" \
  "❄️ Flakes & Environments" "nix flake check" "Validate syntax, types, and flake output structure" \
  "❄️ Flakes & Environments" "nix flake metadata" "Display detailed flake information, URL, and inputs" \
  "❄️ Flakes & Environments" "nix-shell -p <package>" "Open a temporary shell with the specified package (without installing)" \
  "❄️ Flakes & Environments" "nix shell nixpkgs#<package>" "Start an ephemeral shell with packages via Flakes" \
  "❄️ Flakes & Environments" "nix run nixpkgs#<package>" "Download and execute an application in one step without installing" \
  "🧹 Maintenance & Clean" "sudo nix-collect-garbage -d" "Delete old system generations and free disk space" \
  "🧹 Maintenance & Clean" "nix-collect-garbage -d" "Delete old user generations and orphan packages" \
  "🧹 Maintenance & Clean" "sudo nix-store --optimise" "Deduplicate identical files in /nix/store using hard links" \
  "🧹 Maintenance & Clean" "sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system" "Keep only the last 5 system generations" \
  "🧹 Maintenance & Clean" "nix path-info -Sh /run/current-system" "Display total disk size of the current system closure" \
  "🧹 Maintenance & Clean" "sudo nix-store --verify --check-contents" "Verify package integrity in the Nix store" \
  "📊 Generations & History" "nixos-rebuild list-generations" "List all system generations with build dates and kernel version" \
  "📊 Generations & History" "home-manager generations" "List Home Manager generation history" \
  "📊 Generations & History" "nix store diff-closures <link1> <link2>" "Compare two generations and show package version diffs" \
  "🔍 Diagnostics & Logs" "systemctl status <service>" "Check the status of a system systemd service" \
  "🔍 Diagnostics & Logs" "journalctl -u <service> -f" "Follow real-time logs for a specific service" \
  "🔍 Diagnostics & Logs" "systemctl --user status <service>" "Check user-space service status (Pipewire, SwayNC, etc.)" \
  "🔍 Diagnostics & Logs" "journalctl -b -p err" "Show all errors and failures from the current boot" \
  "🔍 Diagnostics & Logs" "nixos-version --json" "Display NixOS version, channel, and commit hash in JSON format" \
  "🔍 Diagnostics & Logs" "nix log <derivation-path>" "View detailed build logs if a build failed"
