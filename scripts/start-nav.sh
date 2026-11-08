#!/bin/sh
exec >> ~/start-nav.log 2>&1
echo "=== $(date '+%H:%M:%S') start-nav begin"
mako &
echo "$(date '+%H:%M:%S') mako launched"
flatpak run io.github.rinigus.OSMScoutServer &
echo "$(date '+%H:%M:%S') scout server launched"
for i in $(seq 1 30); do pgrep -f geoclue-2.0/demos/agent >/dev/null && break; sleep 1; done
echo "$(date '+%H:%M:%S') agent wait done after $i tries"
for i in $(seq 1 30); do [ -S /run/gps-share.sock ] && break; sleep 1; done
echo "$(date '+%H:%M:%S') gps socket wait done after $i tries"
for i in $(seq 1 60); do curl -s -o /dev/null http://localhost:8553/ && break; sleep 1; done
echo "$(date '+%H:%M:%S') scout port wait done after $i tries"
echo "$(date '+%H:%M:%S') launching pure maps"
exec flatpak run io.github.rinigus.PureMaps
