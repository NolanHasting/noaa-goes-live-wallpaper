# GOES Live Wallpaper 🌎

Turn your Mac into a live view of Earth. This small open-source tool downloads NOAA GOES full-disk **GeoColor** satellite imagery and refreshes your macOS desktop wallpaper automatically every **5 minutes**. A separate stable image file is kept ready for use by a compatible macOS photo screensaver.

> **Disclaimer:** Unofficial community project. Not affiliated with NOAA or NASA. Imagery credit: NOAA / NESDIS / STAR and CIRA. Satellite images are observations, not a continuous live video feed. NOAA's source cadence and availability may vary; running every five minutes does not mean new imagery appears every five minutes.

## Requirements

- macOS with a user login session (AppleScript permissions may be needed)
- Python 3 with `venv` and `pip`
- Network access to NOAA's public imagery CDN
- A display resolution you can enter in `config.env`

## Install

1. Download this repository as a ZIP and extract it, or clone it:
   ```bash
   git clone https://github.com/NolanHasting/noaa-goes-live-wallpaper.git
   cd noaa-goes-live-wallpaper
   ```
2. Run:
   ```bash
   chmod +x install.sh uninstall.sh scripts/update.sh
   ./install.sh
   ```
3. If macOS asks whether Terminal or the script may control **System Events**, allow it so wallpaper changes work.
4. Set your actual screen resolution by editing `~/.config/goes-live-wallpaper/config.env`. The initial settings target 3840 × 2160, but the image keeps its proportions for any configured resolution.
5. Test an immediate update:
   ```bash
   ./scripts/update.sh
   ```

**Keep the cloned project folder in place:** the LaunchAgent runs the updater from that location.

## Screensaver

The latest processed image is saved at:

`~/Pictures/GOES Live Wallpaper/goes-current.jpg`

macOS screensaver capabilities vary by release. If your system offers a **Photos / photo-library folder** screensaver, point it at the `GOES Live Wallpaper` folder in **System Settings → Screen Saver**. Some macOS versions may cache images or not offer a direct folder selection; in that case, automatic live screensaver refresh is **not guaranteed**. The desktop wallpaper refresh is the primary supported feature. The script does not modify system screensaver settings on your behalf.

## Customize

Edit `~/.config/goes-live-wallpaper/config.env`:

| Setting | Default | Purpose |
| --- | --- | --- |
| `SATELLITE` | `GOES19` | `GOES19` (east) or `GOES18` (west) |
| `WIDTH` / `HEIGHT` | `3840` / `2160` | Exact output wallpaper pixel dimensions |
| `PADDING` | `32` | Black border around the full disk |
| `KEEP` | `3` | Number of older desktop wallpaper files to keep |

The entire satellite image is fitted inside the output resolution, centered on black; no cropping or stretching of Earth. This is particularly useful on widescreen displays.

**Scheduling:** The installer creates `~/Library/LaunchAgents/com.goeslive.wallpaper.plist`, configured with `StartInterval=300`. It runs when the Mac is awake and the user is logged in; it does not run while sleeping. Restart the agent after configuration changes only if you change the schedule itself. To update an image after editing config: `./scripts/update.sh`.

**Unchanged source:** The updater compares the downloaded image and relevant rendering settings with the last successful wallpaper update. If neither changes, it skips processing. Changes to the satellite, dimensions, or padding take effect on the next refresh even when the downloaded image is unchanged. Failed downloads do not replace the last wallpaper.

## Check that it is running

After installing, allow a minute for the first download, then check that your wallpaper has changed. You can also trigger an immediate update:

```bash
./scripts/update.sh
```

To check the 5-minute LaunchAgent:

```bash
launchctl print "gui/$(id -u)/com.goeslive.wallpaper"
```

Look for output images in `~/Library/Application Support/GOES Live Wallpaper/`, and the screensaver image in `~/Pictures/GOES Live Wallpaper/`. The screensaver folder is not automatically selected by the installer.

## Logs and troubleshooting

```bash
tail -n 50 ~/Library/Logs/goes-live-wallpaper.log
tail -n 50 ~/Library/Logs/goes-live-wallpaper.error.log
```

- If you see `Missing virtual environment`, rerun `./install.sh`.
- If macOS refuses to set the wallpaper, allow automation access for the invoking app in **System Settings → Privacy & Security → Automation** and rerun `./scripts/update.sh`.
- A stable image path is supplied for screensavers, but macOS may not notice an in-place replacement. Test your particular macOS screensaver.
- If NOAA is offline, previously generated files remain available. Failed downloads are logged and retried on the next scheduled run.
- If the image stays unchanged, NOAA might not have published a new frame yet. The updater intentionally skips identical downloads.
- If you edit the configuration, run `./scripts/update.sh` to apply it immediately. Wallpaper permissions must be granted for a successful change.
- For 5K, ultrawide or laptop displays, adjust `WIDTH`/`HEIGHT`.
- The script targets a single configured resolution, so it does **not** tailor each monitor independently on mixed-resolution multi-monitor setups.

## Uninstall

From the cloned directory:

```bash
./uninstall.sh
```

This disables automatic refresh but intentionally preserves the created images, settings, logs, and Python environment. The command prints the paths to remove manually if desired.

## Development

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m unittest discover -s tests -v
bash -n install.sh uninstall.sh scripts/update.sh
```

## Data and attribution

Source: [NOAA STAR GOES imagery](https://www.star.nesdis.noaa.gov/GOES/index.php). GOES satellite and GeoColor imagery courtesy of NOAA/NESDIS/STAR and the Cooperative Institute for Research in the Atmosphere (CIRA). Respect the source provider's availability and attribution guidance. This repository distributes **code only**, not bundled NOAA imagery.

## Contributing

Bug reports, compatibility notes, and pull requests are welcome. If reporting an issue, include your macOS version, monitor resolution, relevant log output (remove personal paths), and whether you installed from a ZIP or clone.

## License

The project code is released under the [MIT License](LICENSE). Satellite imagery remains subject to its provider's terms and attribution guidance.
