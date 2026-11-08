# 01 - OS and display

## OS

- Raspberry Pi 4 running Debian 13 (Trixie)
- Wayland session with the **labwc** compositor, outputs managed by **kanshi**
- Day-to-day work is done over SSH. The Pi's own screen is only used to test GUI apps.

<!-- TODO: note which image/installer you used and how you enabled SSH -->

## The 800x480 screen problem

The 800x480 HDMI screen came up stretched or at the wrong resolution. Two things were needed, and neither was enough alone.

On Trixie, display settings come from the **kernel command line** (`/boot/firmware/cmdline.txt`), not `config.txt`. The Wayland compositor can then override that, so a **kanshi** profile is needed to make the mode stick across reboots.

### 1. Find the connector name

```bash
ls /sys/class/drm/
```

Look for an entry like `card1-HDMI-A-2`. The connector here was `HDMI-A-2`. Yours may be `HDMI-A-1`, depending on which micro-HDMI port the screen is plugged into.

### 2. Kernel command line

Edit `/boot/firmware/cmdline.txt` and add this to the **end of the existing single line** (no new line, space-separated):

```
video=HDMI-A-2:800x480@60D
```

### 3. kanshi profile

Create `~/.config/kanshi/config`. Example (check the syntax against `man 5 kanshi`, since your config may differ):

```
profile {
    output HDMI-A-2 enable mode 800x480@60Hz
}
```

<!-- TODO: replace the example above with your actual ~/.config/kanshi/config -->

kanshi is started by the system-wide labwc autostart file, `/etc/xdg/labwc/autostart`, which on this Pi contains:

```
/usr/bin/lwrespawn /usr/bin/pcmanfm-pi &
/usr/bin/lwrespawn /usr/bin/wf-panel-pi &
/usr/bin/kanshi &
/usr/bin/lxsession-xdg-autostart
```

The last line runs everything in the XDG autostart folders, which is also how the GeoClue demo agent starts. See [03-geoclue-bridge.md](03-geoclue-bridge.md).

### 4. Reboot and check

The screen should come up at 800x480 with no stretching and keep that after another reboot.

## Notes

- Back up `cmdline.txt` before editing it. A typo there can stop the Pi from booting.
- Speech audio uses the Pi's 3.5 mm jack, routed through the screen and on to a small speaker. See [04-offline-maps.md](04-offline-maps.md#audio).
