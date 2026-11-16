#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${GOES_CONFIG:-$HOME/.config/goes-live-wallpaper/config.env}"
if [[ -f "$CONFIG" ]]; then
  # The config belongs to the current user: treat it as shell code and do not use untrusted configs.
  # shellcheck disable=SC1090
  source "$CONFIG"
fi
SATELLITE="${SATELLITE:-GOES19}"
WIDTH="${WIDTH:-3840}"
HEIGHT="${HEIGHT:-2160}"
PADDING="${PADDING:-32}"
KEEP="${KEEP:-3}"
DATA_DIR="${DATA_DIR:-$HOME/Library/Application Support/GOES Live Wallpaper}"
SCREENSAVER_DIR="${SCREENSAVER_DIR:-$HOME/Pictures/GOES Live Wallpaper}"
PYTHON="${GOES_PYTHON:-$ROOT/.venv/bin/python}"

case "$SATELLITE" in GOES18|GOES19) ;; *) echo "SATELLITE must be GOES18 or GOES19" >&2; exit 2 ;; esac
for v in WIDTH HEIGHT PADDING KEEP; do
  value="${!v}"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then echo "$v must be a nonnegative integer" >&2; exit 2; fi
done
if (( WIDTH < 256 || HEIGHT < 256 || PADDING * 2 >= WIDTH || PADDING * 2 >= HEIGHT || KEEP < 1 )); then
  echo 'Invalid dimensions, padding, or KEEP' >&2; exit 2
fi
[[ -x "$PYTHON" ]] || { echo "Missing virtual environment. Run ./install.sh first." >&2; exit 2; }
mkdir -p "$DATA_DIR" "$SCREENSAVER_DIR"
# Lock to avoid overlapping jobs when the network is slow.
LOCK="$DATA_DIR/.running"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo 'Another refresh is running; skipping.'
  exit 0
fi
TMP="$(mktemp -d "$DATA_DIR/.tmp.XXXXXX")"
cleanup() { rm -rf "$TMP"; rmdir "$LOCK" 2>/dev/null || true; }
trap cleanup EXIT

URL="${GOES_IMAGE_URL:-https://cdn.star.nesdis.noaa.gov/$SATELLITE/ABI/FD/GEOCOLOR/5424x5424.jpg}"
if ! curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 --max-time 90 "$URL" -o "$TMP/raw.jpg"; then
  echo 'Download failed; previous wallpaper has been preserved.' >&2
  exit 1
fi
# Image validation is performed by Pillow before replacing any output.
CACHE="$DATA_DIR/latest-source.jpg"
if [[ -f "$CACHE" ]] && cmp -s "$TMP/raw.jpg" "$CACHE"; then
  echo 'NOAA image unchanged; skipping.'
  exit 0
fi
NEW="$DATA_DIR/goes-$(date +%Y%m%d-%H%M%S)-$$.jpg"
"$PYTHON" "$ROOT/scripts/render.py" "$TMP/raw.jpg" "$TMP/rendered.jpg" --width "$WIDTH" --height "$HEIGHT" --padding "$PADDING"
# Prepare all files before changing the displayed wallpaper.
cp "$TMP/rendered.jpg" "$NEW"
cp "$TMP/rendered.jpg" "$SCREENSAVER_DIR/.next-$$.jpg"
mv -f "$SCREENSAVER_DIR/.next-$$.jpg" "$SCREENSAVER_DIR/goes-current.jpg"
cp "$TMP/raw.jpg" "$TMP/latest-source.jpg"
mv -f "$TMP/latest-source.jpg" "$CACHE"
if [[ "${GOES_SKIP_WALLPAPER:-0}" != "1" ]]; then
  if ! osascript - "$NEW" <<'APPLE'
on run argv
  set newImage to POSIX file (item 1 of argv)
  tell application "System Events"
    tell every desktop to set picture to newImage
  end tell
end run
APPLE
  then
    echo 'Image updated, but macOS could not set the wallpaper. Check Automation permissions.' >&2
  fi
fi
# Retain newest N historical wallpapers, leave source cache and current screensaver intact.
find "$DATA_DIR" -maxdepth 1 -type f -name 'goes-*.jpg' -print | sort -r | tail -n +$((KEEP + 1)) | while IFS= read -r old; do rm -f "$old"; done
echo "Updated $SATELLITE wallpaper: $NEW"
