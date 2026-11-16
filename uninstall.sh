#!/bin/bash
set -euo pipefail
PLIST="$HOME/Library/LaunchAgents/com.goeslive.wallpaper.plist"
if [[ -f "$PLIST" ]]; then
  launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
fi
echo 'Automatic refresh disabled. Wallpaper images, settings, logs, and Python environment are preserved.'
echo 'To fully remove, delete the cloned repository, ~/.config/goes-live-wallpaper,'
echo 'and ~/Library/Application Support/GOES Live Wallpaper and ~/Pictures/GOES Live Wallpaper.'
