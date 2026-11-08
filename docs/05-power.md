# 05 - Power

**Status: partly planned.** The car adapter setup is in use. The UPS HAT described below has not been built yet, so treat the UPS sections as the plan and update them once it's installed and tested.

## Current setup

- 12V cigarette-lighter adapter: Anker PowerDrive PD+ 2 (model A2732), feeding the Pi over USB.
- The screen has a microUSB power port and is powered by a separate USB power bank.
- When the car turns off, the outlet cuts power and the Pi stops without a clean shutdown.

Problems with this: the power bank's button sits inside the case, it adds weight, and it can run flat mid-trip.

## Goals

1. Detect that car power is gone and shut the Pi down cleanly.
2. Keep both the Pi and the screen powered during that shutdown.
3. Power on again automatically when the car starts, with no button.

A shutdown takes well under a minute, so only a small battery is needed.

## Plan: Geekworm X728

Options considered and ruled out:

- **PiJuice HAT.** Does what's needed but costs more.
- **Geekworm X703.** Cheaper, but Geekworm lists no safe-shutdown support and I found no power-loss signal for the Pi.
- **DIY with an HW-131 breadboard supply and a 9V battery.** The module is rated for about 700 mA, and a Pi 4 can draw up to about 3 A. A 9V battery can't supply that current. Not a UPS either.

The X728 has a power-loss detection jumper (PLD) that exposes the state on GPIO6, and an auto power-on jumper (AON).

### Parts

- Geekworm X728 (check the listing says Raspberry Pi 4 compatible and note the revision)
- Two **unprotected** 18650 cells from a reputable seller. Geekworm says not to use cells with built-in protection circuits.
- A cable from the X728's XH2.54 2-pin 5V output to microUSB for the screen
- A USB-A to USB-C cable from the adapter to the X728

### Jumpers

- **PLD:** on, so GPIO6 reports loss of external power
- **AON:** on, so the board powers up whenever external power is applied (with a short delay)

### Adapter limits

The adapter's ports are rated at roughly 5V and 3A. The X728 wants at least 3A at 5V on its USB-C input, and that input also feeds the battery charger, which can draw 2.3 to 3.2 A. So there is no margin right after a long stop with drained cells. Use a USB-A to USB-C cable rather than C-to-C, because the X728 does not negotiate PD.

If the adapter can't keep up, either try a higher-current 5V adapter or feed the X728's DC jack (rated for 4 A or more) through a separate 12V-to-5V converter.

### Bench test (do before relying on it)

1. Drain the cells a little by running a few minutes on battery.
2. Plug in the adapter with the Pi running Pure Maps and the screen on.
3. Watch `vcgencmd get_throttled`. It should stay `0x0`.
4. Watch for unexpected shutdowns during the charge.
5. A cheap inline USB power meter on the adapter port shows whether the voltage sags.

## Shutdown watcher

<!-- TODO: add scripts/ups-shutdown.py once written -->

The plan for the script:

- Watch GPIO6.
- When external power is lost, wait a grace period (30 to 60 seconds).
- If power returns within that time, cancel. Otherwise run `shutdown -h now`.

## Screen power

Power the screen from the X728's output instead of a separate power bank.

Open question to check on the board or in testing: whether that output stays live after the Pi halts, or cuts off when the board does its own full power-off.

## Edge cases to test

- Turn the car off and start it again while the Pi is mid-shutdown (it may finish halting without rebooting)
- A frozen Pi, with no way to power cycle it besides unplugging
- Behavior after a low-battery cutoff, and whether AON brings it back when the adapter returns
- Heat: lithium cells in a parked car. Keep them out of direct sun.
