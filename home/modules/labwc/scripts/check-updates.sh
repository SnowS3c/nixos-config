#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/etc/profiles/per-user/${USER:-user}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"

# Apply mode flag: opens terminal to run system upgrade
if [ "${1:-}" = "--apply" ]; then
    TERM_BIN=$(command -v foot || command -v ghostty || command -v alacritty || echo "xterm")
    setsid "$TERM_BIN" -T "NixOS Upgrade" bash -l -c '
        echo "=========================================="
        echo "          NIXOS SYSTEM UPGRADE            "
        echo "=========================================="
        echo ""
        read -r -p "Do you want to update the system and rebuild now? [y/n]: " RESP
        case "$RESP" in
            [yYsS]*)
                echo ""
                if [ -f "/etc/nixos/flake.nix" ]; then
                    echo "=== [Flakes] Updating inputs and rebuilding NixOS ==="
                    if (cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake /etc/nixos#nixos); then
                        echo ""
                        echo "✅ Upgrade completed successfully."
                        pkill waybar 2>/dev/null
                        nohup waybar >/dev/null 2>&1 &
                    else
                        echo ""
                        echo "❌ An error occurred during the upgrade."
                    fi
                else
                    echo "=== [Channels] Updating channels and rebuilding NixOS ==="
                    if sudo nix-channel --update && sudo nixos-rebuild switch; then
                        echo ""
                        echo "✅ Upgrade completed successfully."
                        pkill waybar 2>/dev/null
                        nohup waybar >/dev/null 2>&1 &
                    else
                        echo ""
                        echo "❌ An error occurred during the upgrade."
                    fi
                fi
                ;;
            *)
                echo ""
                echo "Operation cancelled."
                ;;
        esac
        echo ""
        read -r -p "Press Enter to close..."
    ' >/dev/null 2>&1 &
    cat <<EOF
{
  "status": "ok",
  "behind": 0,
  "version": "NixOS Upgrade",
  "changelog": ["Upgrade started in terminal."]
}
EOF
    exit 0
fi

# Get current installed NixOS revision
INSTALLED_REV=$(nixos-version --revision 2>/dev/null | tr -d '\n\r')

# Determine channel name from nix-channel or default to nixos-26.05
CHANNEL_URL=$(nix-channel --list 2>/dev/null | grep nixos | head -n1 | awk '{print $2}')
if [ -n "$CHANNEL_URL" ]; then
    CHANNEL_NAME=$(basename "$CHANNEL_URL")
else
    CHANNEL_NAME="nixos-26.05"
fi

# Fetch remote git revision from channel with -L (follow redirects)
REMOTE_REV=$(curl -sL --max-time 5 "https://channels.nixos.org/${CHANNEL_NAME}/git-revision" 2>/dev/null | tr -d '\n\r')

# Check mode flag
if [ "${1:-}" = "--json-surface" ]; then
    if [ -n "$REMOTE_REV" ] && [[ ! "$REMOTE_REV" =~ "<" ]] && [ -n "$INSTALLED_REV" ]; then
        if [[ "$REMOTE_REV" != "$INSTALLED_REV"* ]]; then
            cat <<EOF
{
  "status": "ok",
  "behind": 1,
  "version": "${CHANNEL_NAME} ${REMOTE_REV:0:7}",
  "fromDate": "${INSTALLED_REV:0:7}",
  "toDate": "${REMOTE_REV:0:7}",
  "changelog": [
    "New version available on channel ${CHANNEL_NAME}",
    "Installed: ${INSTALLED_REV:0:7}",
    "Remote:    ${REMOTE_REV:0:7}"
  ]
}
EOF
        else
            cat <<EOF
{
  "status": "ok",
  "behind": 0,
  "version": "${CHANNEL_NAME} ${INSTALLED_REV:0:7}",
  "fromDate": "${INSTALLED_REV:0:7}",
  "toDate": "${INSTALLED_REV:0:7}",
  "changelog": []
}
EOF
        fi
    else
        cat <<EOF
{
  "status": "ok",
  "behind": 0,
  "version": "${CHANNEL_NAME}",
  "changelog": []
}
EOF
    fi
    exit 0
fi

# Default bar output
if [ -n "$REMOTE_REV" ] && [[ ! "$REMOTE_REV" =~ "<" ]] && [ -n "$INSTALLED_REV" ]; then
    if [[ "$REMOTE_REV" != "$INSTALLED_REV"* ]]; then
        # Update available
        printf '{"text":"󰚰","tooltip":"Update available for NixOS (%s)\\nInstalled: %s\\nAvailable: %s\\n\\nClick to upgrade","class":"has-updates"}\n' "$CHANNEL_NAME" "${INSTALLED_REV:0:7}" "${REMOTE_REV:0:7}"
    else
        # System up to date (hidden)
        printf '{"text":"","tooltip":"","class":""}\n'
    fi
else
    # Offline or fallback (hidden)
    printf '{"text":"","tooltip":"","class":""}\n'
fi
