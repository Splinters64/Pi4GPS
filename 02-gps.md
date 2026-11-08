# 02 - GPS puck and gpsd

## Hardware

VK-162 G-Mouse USB GPS puck. It enumerates as a serial device, `/dev/ttyACM0` here.

## Install

```bash
sudo apt install gpsd gpsd-clients
```

## Configure gpsd

Edit `/etc/default/gpsd`:

```
DEVICES="/dev/ttyACM0"
GPSD_OPTIONS="-n"
```

`-n` tells gpsd to start reading the device immediately instead of waiting for a client, so a fix is ready when an app connects.

Then enable and restart:

```bash
sudo systemctl enable --now gpsd
sudo systemctl restart gpsd
systemctl status gpsd
```

## Check the device

```bash
ls -l /dev/ttyACM0
```

If the device name is different on your system, update `DEVICES` to match.

## Validate a fix

```bash
cgps -s
```

A good result shows a 3D fix and several satellites in use. On the first test here this showed a 3D fix with 9 satellites used and a 2D error of about 17.5 m. A cold start can take a few minutes with a clear view of the sky.

## Next

gpsd alone is not enough for Pure Maps, which gets its position from GeoClue2. See [03-geoclue-bridge.md](03-geoclue-bridge.md).
