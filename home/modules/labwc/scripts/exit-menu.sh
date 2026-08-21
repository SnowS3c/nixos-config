#!/usr/bin/env bash

# Exit Menu / Power Menu for labwc using Wofi (Centered GTK card style)

# Check if exit-menu wofi instance is already running, toggle it
if pgrep -f "exit-menu-config" > /dev/null; then
    pkill -f "exit-menu-config"
    exit 0
fi

# Define options in fixed order with tab (\t) spacing
POWEROFF=$'⏻\tPower off'
REBOOT=$'🗘\tReboot'
SUSPEND=$'⏸\tSuspend'
LOGOUT=$'\tLog out'
LOCK=$'🗝\tLock screen'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/exit-menu-config"
STYLE_FILE="$SCRIPT_DIR/exit-menu-style.css"

CHOSEN=$(printf "%s\n%s\n%s\n%s\n%s" "$POWEROFF" "$REBOOT" "$SUSPEND" "$LOGOUT" "$LOCK" | wofi \
    --dmenu \
    --conf "$CONFIG_FILE" \
    --style "$STYLE_FILE" \
    --cache-file /dev/null \
    --prompt "Action:" \
    --width 380 \
    --height 370 \
    --location center \
    --insensitive)

case "$CHOSEN" in
    *"Power off")
        systemctl poweroff
        ;;
    *"Reboot")
        systemctl reboot
        ;;
    *"Suspend")
        systemctl suspend
        ;;
    *"Log out")
        labwc --exit
        ;;
    *"Lock screen")
        hyprlock
        ;;
    *)
        exit 0
        ;;
esac
