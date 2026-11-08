# 03 - GeoClue2 bridge

Pure Maps is a Flatpak app and gets its position from **GeoClue2**, not from gpsd directly. GeoClue2 doesn't read gpsd by itself, so a small bridge feeds the puck's NMEA data into it. This was the hardest part of the build, and several separate pieces all had to be in place at once.

```
VK-162 -> gpsd -> gpspipe -> socat (/run/gps-share.sock) -> GeoClue2 -> Pure Maps
```

## What needs to be running

1. **gpsd** (see [02-gps.md](02-gps.md))
2. **The bridge:** `gpspipe` piped into `socat`, which listens on a Unix socket that GeoClue reads
3. **GeoClue2** (restart it after the bridge starts)
4. **A GeoClue demo agent.** Exactly one. A second copy caused problems.
5. **A notification daemon** (`mako`). Pure Maps' positioning fails without one.
6. **A section for Pure Maps in `/etc/geoclue/geoclue.conf`**

## Install

```bash
sudo apt install socat geoclue-2-demo mako-notifier
```

## The bridge command

Run by hand, this is:

```bash
gpspipe -r | sudo socat - UNIX-LISTEN:/run/gps-share.sock,fork,perm=666
```

`perm=666` makes the socket readable and writable by the GeoClue service.

### As a systemd service

The bridge runs as `/etc/systemd/system/gps-bridge.service`. It is enabled so that it starts at boot.

<!-- TODO: paste your actual gps-bridge.service here (cat /etc/systemd/system/gps-bridge.service) -->

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gps-bridge.service
```

## GeoClue configuration

Add a section to `/etc/geoclue/geoclue.conf` allowing Pure Maps (the Flatpak app ID) to ask for location:

```
[io.github.rinigus.PureMaps]
allowed=true
system=false
users=
```

Then restart GeoClue:

```bash
sudo systemctl restart geoclue
```

The Pure Maps Flatpak already has permission to talk to GeoClue (`org.freedesktop.GeoClue2=talk`). You can check with `flatpak info --show-permissions io.github.rinigus.PureMaps`.

## Demo agent

GeoClue needs an agent to authorize apps. The demo agent from `geoclue-2-demo` is at `/usr/libexec/geoclue-2.0/demos/agent`.

On this Pi it starts at login through `/etc/xdg/autostart/geoclue-demo-agent.desktop`, which the system labwc autostart runs via `lxsession-xdg-autostart`. The packaged entry, `/etc/xdg/autostart/geoclue-demo-agent.desktop`, looks like this:

```ini
[Desktop Entry]
Name=Geoclue Demo agent
GenericName=Demo geoclue agent
Keywords=geolocation;
Exec=/usr/libexec/geoclue-2.0/demos/agent
Icon=mark-location-symbolic
NotShowIn=GNOME;
NoDisplay=true
Terminal=false
Type=Application
```

Check that exactly one is running:

```bash
pgrep -a agent
```

## Notification daemon

Install `mako-notifier` and make sure it is running before Pure Maps starts.

`mako`, OSM Scout Server and Pure Maps are started in the right order by a launch script, [`scripts/start-nav.sh`](../scripts/start-nav.sh). See [04-offline-maps.md](04-offline-maps.md#auto-start).

## Test the chain

```bash
/usr/libexec/geoclue-2.0/demos/where-am-i
```

A continuously updating position here means GeoClue is receiving the puck's fixes. Lines labelled `GPS GGA+RMC` are coming from the puck, not from a WiFi lookup.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Pure Maps starts on a Europe view, and "Share current position" is greyed out ("not ready") | Position isn't reaching Pure Maps. Work through the chain above, starting with `where-am-i`. |
| Qt positioning log shows `org.freedesktop.Notifications was not provided by any .service files` | No notification daemon is running. Install and start `mako`. |
| Log then shows `Unable to start the client ... Timeout was reached` | Seen right after `mako` was installed. It went away once the `[io.github.rinigus.PureMaps]` section was added to `geoclue.conf`, GeoClue was restarted, and only a single demo agent was running. |
| Works, then stops after a reboot or crash | Restart in order: bridge, GeoClue, one demo agent, mako, then Pure Maps. |

To capture Pure Maps' positioning log when debugging:

```bash
QT_LOGGING_RULES="qt.positioning.*=true" flatpak run io.github.rinigus.PureMaps 2>&1 | tee ~/puremaps.log
```

<!-- TODO: confirm the exact logging rule you used; adjust if it differs -->
