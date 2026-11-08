# Build guide

A step-by-step path for building something similar. It follows the order this build was done in and links to the detailed page for each step.

**Status:** this guide is assembled from one build, on one Pi. The steps have not been repeated from a fresh SD card, so expect gaps. If a step doesn't match what you see, check [lessons-learned.md](lessons-learned.md) first, then open an issue.

## Before you start

You should be comfortable with:

- SSH and the Linux command line
- Editing config files (this build used `nano`)
- Installing packages with `apt` and `flatpak`

Parts (see the README for details):

- Raspberry Pi 4, SD card (32 GB or larger is comfortable for one state's map data)
- A screen (this build uses an 800x480 HDMI screen)
- USB GPS puck (VK-162 G-Mouse)
- A speaker and the audio cabling to drive it
- 12V car power for the Pi. A UPS for clean shutdown is planned. See [05-power.md](05-power.md).

Read [design-decisions.md](design-decisions.md) first if you want to know why these pieces were chosen.

## Steps

Each step ends with a check. Don't move on until it passes.

### 1. OS and display

Install Debian 13 (Trixie) and get the screen showing the right resolution. See [01-os-and-display.md](01-os-and-display.md).

**Check:** the screen is 800x480 with no stretching, and stays that way after a reboot.

### 2. GPS

Install gpsd and point it at the puck. See [02-gps.md](02-gps.md).

**Check:** `cgps -s` shows a 3D fix with several satellites.

### 3. GPS position for Pure Maps

Bridge the puck's data into GeoClue2. See [03-geoclue-bridge.md](03-geoclue-bridge.md). This is the hardest step.

**Check:** `/usr/libexec/geoclue-2.0/demos/where-am-i` prints a continuously updating position.

### 4. Offline maps, search and routing

Install OSM Scout Server and Pure Maps, download your region's data, and set Pure Maps' Profile to Offline. See [04-offline-maps.md](04-offline-maps.md).

**Check:** with WiFi off, a place search works and a route can be started.

### 5. Start everything automatically

Use the launch script and autostart entry so the Pi boots straight into Pure Maps. See [04-offline-maps.md](04-offline-maps.md#launching-it-at-login).

**Check:** after a reboot, Pure Maps opens by itself with a GPS position. If not, read `~/start-nav.log`.

### 6. Road test

Take it in the car. The spoken turn instructions only happen while moving, so this is the first real test of speech.

### 7. Power (when you're ready)

Add safe shutdown and a clean power source. See [05-power.md](05-power.md). This part is planned and not yet tested.

## Things that will probably differ for you

- **Different region:** subscribe to your region in OSM Scout Server instead of Washington State.
- **Different screen:** the display steps are specific to an 800x480 HDMI screen and your connector name.
- **Different Pi or OS:** this was built on a Pi 4 with Debian 13. Other combinations may behave differently.
