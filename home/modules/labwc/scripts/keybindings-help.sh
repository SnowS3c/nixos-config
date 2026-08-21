#!/usr/bin/env bash

# Keybindings Help Dialog using YAD GTK List Table

yad --list \
  --title="Keyboard Shortcuts & Help — labwc" \
  --window-icon="preferences-desktop-keyboard-shortcuts" \
  --width=680 \
  --height=560 \
  --center \
  --column="Category":TEXT \
  --column="Shortcut":TEXT \
  --column="Action":TEXT \
  --button="Close:0" \
  "🚀 General Apps" "Super + Space" "Open Application Launcher (Wofi)" \
  "🚀 General Apps" "Super + T" "Open Terminal (foot)" \
  "🚀 General Apps" "Super + W" "Open Web Browser (Brave)" \
  "🚀 General Apps" "Super + E" "Open File Manager (Thunar)" \
  "🚀 General Apps" "Super + A" "Open Code Editor (Antigravity IDE)" \
  "🪟 Window Control" "Super + Q" "Close Active Window" \
  "🪟 Window Control" "Super + F" "Toggle Fullscreen" \
  "🪟 Window Control" "Super + M / Super + 5" "Toggle Maximize" \
  "🪟 Window Control" "Super + 0" "Center Ultrawide Window (21:9)" \
  "🪟 Window Control" "Super + N" "Minimize Window" \
  "🪟 Window Control" "Super + D" "Toggle Window Decorations" \
  "🪟 Window Control" "Super + Left / Right" "Snap Window to Left / Right Edge" \
  "🪟 Window Control" "Alt + Tab" "Switch to Next Window" \
  "🪟 Window Control" "Alt + Shift + Tab" "Switch to Previous Window" \
  "🖥️ Workspaces & System" "Super + 1..4" "Switch to Virtual Desktop 1..4" \
  "🖥️ Workspaces & System" "Super + Shift + 1..4" "Move Window to Desktop 1..4" \
  "🖥️ Workspaces & System" "Super + L" "Lock Screen (hyprlock)" \
  "🖥️ Workspaces & System" "Print / Super+Shift+S" "Screenshot Editor (Flameshot)" \
  "🖥️ Workspaces & System" "Super + Shift + R" "Reload labwc Configuration" \
  "🖥️ Workspaces & System" "Super + Escape" "Open Exit Menu / Power Options" \
  "🖥️ Workspaces & System" "Super + F1" "Open this Help Window" \
  "🚨 Emergency Recovery" "Ctrl + Alt + Backspace" "Kill Graphical Session & Return to SDDM" \
  "🚨 Emergency Recovery" "Alt + SysRq/Print + K" "Kernel SAK: Force Kill Frozen GUI / VT"
