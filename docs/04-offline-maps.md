# 04 - Offline maps, search and routing

Everything runs on the Pi, with no network needed once the data is downloaded.

- **OSM Scout Server** serves map tiles, address search and routing from local OpenStreetMap data.
- **Pure Maps** is the navigation app, and talks to the server.

Both are installed as user Flatpaks, which avoids the polkit authentication problems that system-wide installs over SSH can hit.

## Install

```bash
flatpak install --user flathub io.github.rinigus.OSMScoutServer
flatpak install --user flathub io.github.rinigus.PureMaps
```

The Flatpak app ID is `io.github.rinigus.OSMScoutServer`. Check with `flatpak list` if a command fails, because similar-looking IDs exist.

## Download map data

Open OSM Scout Server and subscribe to your region. Here that was Washington State (North America > US > Washington). The data lands in `~/Maps.OSM`, **not** in the app's Flatpak folder under `~/.var/app/`.

| Folder | What it holds | Size (Washington) |
|---|---|---|
| `mapboxgl/` | map tiles | ~879 MB |
| `valhalla/` | routing | ~365 MB |
| `postal/` | address parsing | ~204 MB |
| `geocoder-nlp/` | search | ~174 MB |

About 1.6 GB in total. On the 29 GB SD card used here, about 14 GB was still free afterwards.

## Check the server

With the server running, it listens on `127.0.0.1:8553`:

```bash
ss -ltn | grep 8553
curl -i "http://localhost:8553/v2/search?limit=3&search=Seattle"
curl -s "http://localhost:8553/v1/mbgl/style?style=osmbright" | head
curl -s -o /dev/null -w "%{http_code} %{size_download}\n" "http://localhost:8553/v1/mbgl/tile?z=10&x=164&y=357"
```

Expected: the search returns HTTP 200 with results, the style call returns an "OSM Bright" style, and the tile call returns 200 with about 95 KB. A plain `curl localhost:8553/` replying "Unknown URL path" is normal.

## Set Pure Maps to Offline (the key step)

By default Pure Maps uses online map providers and does not list OSM Scout Server at all. The Maps menu only showed online sources like OpenFreeMap and MapTiler, even with the server running.

The fix is the **Profile** setting in Pure Maps' main menu. Options are Online, Offline, HERE (disabled without an API key) and Mixed. Select **Offline**. After that:

- OSM Scout Server entries appear in the Maps menu
- search works (tested with Pike Place Market)
- routing works

## Voice directions

Turn on Pure Maps' speech setting. It says "starting navigation" when a route begins. It does not speak turn instructions while the GPS is stationary, so test while moving. Spoken turn-by-turn directions were confirmed working in a road test.

## Audio

Current path (works, but is a DIY arrangement):

```
Pi 3.5 mm jack -> screen "audio in" -> screen "audio out" -> 3.5 mm cable -> speaker
```

- Speaker: Adafruit 3" diameter, 8 ohm, 1 W
- The speaker wires are twisted onto the stripped end of a 3.5 mm audio cable, not soldered
- The screen's audio in/out routing is how the original Piper computer was set up
- Earlier testing with espeak-ng confirmed audio also works over HDMI

Possible improvements (none are required if it sounds fine):

- **Twisted joints won't last in a car.** Vibration works them loose. Solder them, or use a 3.5 mm jack breakout with screw terminals.
- **Connect the speaker between the plug's tip and sleeve (ground).** Wiring it across tip and ring (left and right) can cancel mono speech and make it very quiet.
- **A headphone output isn't designed to drive an 8 ohm speaker.** If volume is too low or the sound distorts, a small amplifier board between the jack and the speaker is the usual fix. The Adafruit PAM8302 mono 2.5 W class D amp is one example. It runs from 5V and I haven't tested it with this build.
- **Noise.** With the Pi on there is a faint whine or hum. With the Pi off but the screen still powered from its power bank there is a quiet repetitive clicking. The cause hasn't been found. Likely suspects are the screen's power source and a ground loop through the audio cable. See the isolation tests below.
- **Check the volume chain.** Pi volume, Pure Maps' speech volume and any level on the screen all apply.

### Isolating the noise

Run these one at a time and note what changes:

1. Pi off, screen on: unplug the cable from the screen's audio out. If the clicking stops, the speaker is picking it up through that cable.
2. Pi off, screen on: unplug the Pi's audio cable from the screen's audio in. If the clicking stops there, it comes in through that input. If it stays, it comes from the screen itself.
3. Power the screen from a different USB source (a wall charger, for example) in place of the power bank. If the clicking goes away, the power bank is the cause.
4. Pi on: see whether the whine changes when the map redraws or the CPU is busy. If it does, it's noise coming through the Pi's analog audio jack.

Possible fixes, depending on the result: a 3.5 mm ground-loop isolator, powering the screen from the same supply as the Pi, or a small USB audio adapter in place of the Pi's analog jack.

## True offline test

Turn off WiFi on the Pi and repeat a search and a route. With WiFi off, search, map display and routing all worked in Pure Maps.

## Auto-start

[`scripts/start-nav.sh`](../scripts/start-nav.sh) starts everything in order so the Pi goes straight into Pure Maps after boot. Install it with:

```bash
cp scripts/start-nav.sh ~/start-nav.sh
chmod +x ~/start-nav.sh
```

What it does:

1. Logs everything to `~/start-nav.log`, with timestamps.
2. Starts `mako` (notification daemon) and OSM Scout Server in the background.
3. Waits up to 30 seconds for the GeoClue demo agent to be running.
4. Waits up to 30 seconds for the GPS bridge socket, `/run/gps-share.sock`.
5. Waits up to 60 seconds for OSM Scout Server to answer on port 8553.
6. Replaces itself with Pure Maps (`exec`), so closing Pure Maps ends the script.

The GPS bridge (`gps-bridge.service`) and the GeoClue demo agent are not started here. They are started by systemd and the XDG autostart entry. See [03-geoclue-bridge.md](03-geoclue-bridge.md).

Each wait loop gives up after its limit and carries on anyway. The log line says "after N tries", so a value equal to the limit (30 or 60) probably means it timed out, though it could also mean success on the very last try. Check `~/start-nav.log` first if something doesn't come up.

### Launching it at login

The script is started by an XDG autostart entry. Copy [`config/start-nav.desktop`](../config/start-nav.desktop) to `~/.config/autostart/` (create the folder if needed) and edit `<user>` in the `Exec=` line to your username:

```ini
[Desktop Entry]
Type=Application
Name=Start Navigation
Exec=/home/<user>/start-nav.sh
Terminal=false
```

`Exec=` needs the full path, because `~` isn't expanded there. The system labwc autostart (`/etc/xdg/labwc/autostart`) runs `lxsession-xdg-autostart`, which picks this file up at login. Using this folder, instead of creating a per-user labwc autostart, leaves the system autostart (kanshi and the GeoClue demo agent) untouched.

## Updating maps

<!-- TODO: note how you update map data and how often -->
