# Design decisions

Why this build looks the way it does, and what else could have worked.

This was reached mostly by trial and elimination, not by a full up-front comparison. Several options below were tried on the Pi. Others were assessed from documentation and never built. The tables say which is which.

## Requirements

- Works fully **offline** (no network needed while driving)
- **Spoken turn-by-turn** directions
- Address and place **search**
- Rerouting when you miss a turn
- Runs on a Raspberry Pi 4 using open-source software
- As little custom code as possible

## Navigation software

| Option | Tried? | Result |
|---|---|---|
| **Pure Maps + OSM Scout Server** | Yes | **Chosen.** Search, offline routing and speech all work. Needs a GeoClue bridge, a notification daemon and a config entry to get a GPS position. |
| Navit + espeak-ng | Yes | Worked after heavy repair, then dropped. The Debian package ships without layout files, the packaged binary rejected newer layout files, speech and zoom needed config changes, and address search had broken confirm icons. Details in [lessons-learned.md](lessons-learned.md). |
| Organic Maps (Linux desktop build) | Yes | Installed and useful for browsing, but has no voice guidance on Linux. |
| Android navigation apps via Waydroid | No | Ruled out from research. GPS passthrough for an external USB receiver has had an open issue for years, and the chain from USB to gpsd to the container to Android's location layer is fragile. |
| Custom web app (Valhalla + MapLibre) | No | A fair alternative, described below. |
| GNOME Maps | No | Not evaluated. Whether it can map and route offline wasn't confirmed. |

### Custom Valhalla + MapLibre app

A common suggestion is to run a local routing engine (Valhalla) and write your own web frontend (MapLibre) that reads the GPS from gpsd. Valhalla is a good fit for a Pi, and it is also the routing engine behind this build (OSM Scout Server's data folder includes a `valhalla/` directory).

The difference is the amount of code you write. The routing engine alone doesn't cover:

- offline map tiles (MapLibre needs a tile source you host)
- address and place search, which needs its own geocoder
- turning instruction text into speech
- off-route detection, rerouting, and snapping the GPS position to the road
- the user interface

This build gets all of those from existing programs, with no app code of its own. The trade-off is glue: the GPS bridge, GeoClue configuration, notification daemon and launch script documented in this repo. A custom app would avoid that glue in exchange for writing and maintaining the pieces above. If you want more control and don't mind that work, it's a reasonable route.

## GPS position path

Pure Maps is a Flatpak app and takes its position from GeoClue2, not directly from gpsd. A small bridge (`gpspipe` into `socat`) feeds the puck's output into GeoClue. It is the least elegant part of the build, but it uses only standard packages. See [03-geoclue-bridge.md](03-geoclue-bridge.md).

## Power

| Option | Result |
|---|---|
| **Geekworm X728** | **Planned.** Has a power-loss detection pin for safe shutdown, auto power-on, and a 5V output that can power the screen. Not built yet. |
| PiJuice HAT | Would also do the job, but costs more. |
| Geekworm X703 | Cheaper, but Geekworm lists no safe-shutdown support and no power-loss signal for the Pi. |
| DIY with a breadboard supply and a 9V battery | Ruled out. The supply is rated for about 700 mA, a Pi 4 can draw about 3 A, and a 9V battery can't deliver that. Not a UPS either. |

Details and open questions are in [05-power.md](05-power.md).

## Known weaknesses

- Pure Maps is designed around phones and touch input, so entering destinations on a setup without a touchscreen may be awkward.
- The start-up chain has several parts that must be running in the right order. The launch script waits for each, but any one failing means no position or no maps.
- The build has only been done once, on one Pi. Instructions here may have gaps that only show up when someone rebuilds from scratch.
