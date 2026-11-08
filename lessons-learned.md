# Lessons learned

Dead ends and fixes from this build, so others can skip them. This was written for Debian 13 (Trixie) on a Raspberry Pi 4. Other versions may behave differently.

## Where it ended up

Navit worked after a lot of repair on Debian Trixie, but Pure Maps with OSM Scout Server needed much less patching of the app itself and is what the build uses now. Pure Maps needs a GeoClue bridge, a notification daemon and a config entry, so it has more moving parts than Navit did. Navit talked to gpsd directly.

## Pure Maps

- **Set the Profile to Offline.** Without it, OSM Scout Server never appears in the Maps menu. See [04-offline-maps.md](04-offline-maps.md).
- **Pure Maps needs a notification daemon** for positioning to start. No daemon gives a `org.freedesktop.Notifications` error in its Qt positioning log.
- **Only one GeoClue demo agent.** See [03-geoclue-bridge.md](03-geoclue-bridge.md).
- **Map data is not in the app's Flatpak folder.** It's in `~/Maps.OSM`.
- **Speech doesn't say anything while you're stationary.** You hear "starting navigation" only. Test while moving.

## Navit (tried first)

Several separate problems, mostly from the Debian packaging:

- **Blank yellow map.** The `navit-data` package ships without the layout XML files (reported as Debian bug #967960). The layout files have to be downloaded separately.
- **Match the version.** Downloading the layout from the project's main branch broke startup, with a fatal `Unknown element 'spikes'` parse error, because it's newer than the packaged binary (0.5.6). The layout file from the matching `v0.5.6` git tag worked. The file is `navit_layout_car_shipped.xml`.
- **No spoken directions.** The default `<speech>` tag was a placeholder that just ran `echo`. This works:
  ```xml
  <speech type="cmdline" data="espeak-ng '%s'" cps="15"/>
  ```
- **No zoom controls.** The internal GUI draws none by default. The zoom OSD buttons existed but were disabled, and enabling them plus binding keys to `=` and `-` fixed it.
- **On-screen keyboard grabbed typing.** Adding `keyboard="false"` to the active `<gui type="internal">` tag stopped it intercepting a hardware keyboard.
- **Address search returned nothing.** The search screen's country defaulted to Great Britain. Switch it to USA.
- **Search confirm icons were broken** in the Town, Street and House Number flow. Not resolved.
- **Workaround:** entering a destination by latitude and longitude worked cleanly, including spoken directions.
- **Maps:** a Washington State `.bin` came from Navit's fallback map server (about 290 MB).

## Organic Maps

Installed fine as a user Flatpak and was good for browsing, but its Linux desktop build has no voice guidance, so it can't be the main app if audible turn-by-turn is a requirement.

## Waydroid

Looked at running Android navigation apps through Waydroid, and ruled it out. GPS passthrough for an external USB receiver has had an open issue for years, and the chain from USB to gpsd to the container to the Android location layer is fragile.

## Flatpak

- Installing system-wide over SSH hit polkit authentication problems. User installs (`flatpak install --user ...`) avoid this.
- Double-check app IDs with `flatpak list`. A near-miss ID wasted time.

## Display

- Trixie takes display settings from `/boot/firmware/cmdline.txt`, not `config.txt`, and the compositor can override them. Add a kanshi profile too. See [01-os-and-display.md](01-os-and-display.md).
