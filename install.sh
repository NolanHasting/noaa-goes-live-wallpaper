#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == "Darwin" ]] || { echo 'This installer requires macOS.' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v python3 >/dev/null || { echo 'Install Python 3 first (python.org or Homebrew).' >&2; exit 1; }
command -v curl >/dev/null || { echo 'curl is required.' >&2; exit 1; }
python3 -m venv "$ROOT/.venv"
"$ROOT/.venv/bin/python" -m pip install --disable-pip-version-check -r "$ROOT/requirements.txt"
CONFIG_DIR="$HOME/.config/goes-live-wallpaper"
mkdir -p "$CONFIG_DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
if [[ ! -f "$CONFIG_DIR/config.env" ]]; then
  cp "$ROOT/config.example.env" "$CONFIG_DIR/config.env"
fi
PLIST="$HOME/Library/LaunchAgents/com.goeslive.wallpaper.plist"
# Generate valid XML even if the home directory or cloned folder has special characters.
"$ROOT/.venv/bin/python" - "$ROOT" "$PLIST" <<'PY'
import plistlib, sys
from pathlib import Path
root, dest = sys.argv[1:]
content = {
    'Label': 'com.goeslive.wallpaper',
    'ProgramArguments': ['/bin/bash', str(Path(root) / 'scripts' / 'update.sh')],
    'RunAtLoad': True,
    'StartInterval': 300,
    'StandardOutPath': str(Path.home() / 'Library/Logs/goes-live-wallpaper.log'),
    'StandardErrorPath': str(Path.home() / 'Library/Logs/goes-live-wallpaper.error.log'),
}
with open(dest, 'wb') as f:
    plistlib.dump(content, f)
PY
UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM" "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
echo 'Installed. Wallpaper will refresh every 5 minutes when your Mac is awake.'
echo "Configuration: $CONFIG_DIR/config.env"
echo 'For screensaver setup, see README.md (macOS requires manual selection of a photo folder).'
