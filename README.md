# umonitor
Manage monitor configuration automatically

The goal of this project is to implement *desktop environment independent* dynamic monitor
management. Dynamic monitor management means that the positions and resolutions
of the monitors will automatically be updated whenever monitors are
hotplugged. This program is written in Cython using XCB to directly communicate with the X11 server. This program is targeted at users who are using a window manager on a laptop who hotplug monitors frequently.

# Installation
Run `python setup.py install`. Then running `umonitor` should work.

For Arch Linux users there is an AUR package [here](https://aur.archlinux.org/packages/python-umonitor-git/).

# Usage

* Setup your monitor resolutions and positions using `xrandr` or related tools (`arandr` is a good one).
* Run `umonitor --save <profile_name>`.
* Run `umonitor --listen --daemonize` to daemonize the program and begin automatically applying monitor setup.

The configuration file is stored in `~/.config/umon/umon.conf`. You can load a
profile manually by executing `umonitor --load <profile_name>`. Profiles can be deleted `umonitor --delete <profile_name>`.

`umonitor` runs all scripts automatically in `~/.config/umon` after a profile has been loaded. An example script that I use can be seen in `toggle_media.py`.

Example scenario: You are working on a laptop. You want to save just the monitor
configuration of just the laptop screen into the profile name called 'home'. At
home you plug in an external monitor, and you want to save that configuration as
'docked'.

```
# With only the laptop screen (no external monitors)
$ umonitor --save home
Profile home saved!

# Plug in external monitor

# Setup your desired configuration
$ xrandr --output HDMI-1 --mode 1920x1080 --pos 1600x0
$ xrandr --output eDP1 --mode 1600x900 --pos 0x0

# Save the current configuration into a profile
$ umonitor --save docked
Profile docked saved!

# Begin autodetecting changes in monitor
$ umonitor --listen
home
docked*
---------------------------------
# Monitor is unplugged
home*
docked
---------------------------------
```

Program help can also be viewed through `umonitor --help`.

If you would like to auto start this program, you can add the program to your .xinitrc:
```
$ cat ~/.xinitrc
#!/bin/sh
...
...
...
umonitor --listen --daemonize
exec i3 # your window manager of choice
```

# Features
Give me some feedback!

* What is saved and applied dynamically:
  * Monitor vendor name + model number
  * Crtc x and y position
  * Resolution and refresh rate
  * Primary output
  * Rotation
* Runs scripts in `~/.config/umon` with the currently loaded parameter stored in the environment variable `UMONITOR_PROFILE`.
* Valgrind clean

Bugs:
  * Tell me! Run umonitor with the `--verbose` flag to get debugging output

I'm open for any feature requests!

# About
This is a Python rewrite of my earlier program [umonitor](https://github.com/rliou92/umonitor), which was written in C. A higher level language such as Python allows quicker development times and easier maintenance.

# Credits
I borrowed the edid parsing code from [eds](https://github.com/compnerd/eds).
