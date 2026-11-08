# Offline Raspberry Pi Turn-by-Turn GPS

A DIY in-car GPS navigator built on a Raspberry Pi 4. It works fully offline and speaks turn-by-turn directions, using an open-source stack instead of a commercial navigation service.

**Status:** Road-tested and working. Power management (clean shutdown when the car turns off) is the main open item. See [Roadmap](#roadmap).

<!-- TODO: add a photo of the finished device in the car -->

## How it works

```
USB GPS puck -> gpsd -> socat bridge -> GeoClue2 -> Pure Maps
                                                      |
                              OSM Scout Server (offline maps, search, routing)
```

- **gpsd** reads the GPS puck.
- A small systemd service (`gps-bridge.service`) feeds gpsd data into **GeoClue2**, so Flatpak apps can see the position.
- **OSM Scout Server** serves offline map tiles, search and routing from local OpenStreetMap data.
- **Pure Maps** is the navigation UI. It must be set to the *Offline* profile to use the local server.
- Spoken instructions come from Pure Maps' built-in speech.

## Hardware

| Part | Notes |
|---|---|
| Raspberry Pi 4 | |
| 800x480 HDMI screen | Powered over microUSB |
| VK-162 G-Mouse USB GPS puck | Shows up as `/dev/ttyACM0` |
| 12V car adapter | Anker PowerDrive PD+ 2 (A2732) |
| UPS HAT (planned) | Geekworm X728 + two unprotected 18650 cells |

<!-- TODO: add wiring/power notes and any enclosure details -->

## Software

- Debian 13 (Trixie), Wayland with labwc
- gpsd, socat, GeoClue2 (+ demo agent), mako (notification daemon)
- OSM Scout Server and Pure Maps (Flatpak, user install)
- Offline map data: Washington State (see [docs/04-offline-maps.md](docs/04-offline-maps.md))

## Setup

Start with the [build guide](docs/build-guide.md), which walks through the steps in order. [Design decisions](docs/design-decisions.md) explains why these pieces were chosen. Detailed notes live in `docs/`:

1. `docs/01-os-and-display.md` - OS, 800x480 display config
2. `docs/02-gps.md` - gpsd and the GPS puck
3. `docs/03-geoclue-bridge.md` - GeoClue2 bridge and autostart
4. `docs/04-offline-maps.md` - OSM Scout Server and Pure Maps profile
5. `docs/05-power.md` - car power and UPS

<!-- TODO: write each doc from your shell history and notes -->

## Repository layout

```
config/    config files and where each belongs on the Pi
scripts/   helper scripts (e.g. the power-loss shutdown watcher)
docs/      setup guides and lessons learned
```

## Lessons learned

See [docs/lessons-learned.md](docs/lessons-learned.md). Highlights from the Navit, Organic Maps and Waydroid detours go there so others can skip them.

## Roadmap

- [ ] UPS HAT with safe shutdown when car power is lost
- [ ] Power the screen from the UPS instead of a separate power bank
- [ ] Spoken-turn testing while moving
- [ ] Custom enclosure
- [ ] Software and quality-of-life improvements

## Credits and third-party software

This project configures and glues together existing open-source software. See each project for its own license:

- [Pure Maps](https://github.com/rinigus/pure-maps)
- [OSM Scout Server](https://github.com/rinigus/osmscout-server)
- [gpsd](https://gpsd.io/)
- [GeoClue](https://gitlab.freedesktop.org/geoclue/geoclue)

Map data (c) OpenStreetMap contributors, available under the [ODbL](https://www.openstreetmap.org/copyright).

## License

<!-- TODO: add a LICENSE file (e.g. MIT) and name it here -->
