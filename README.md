![Preview](addons/tcps/assets/tcps.png)

# Tim Cope's Pro Skater (TCPS) for Godot 4.8+

A rideable skateboard with tricks, grinds and its own camera, built on the player controller's
riding contract.

**[Read the full documentation](addons/tcps/README.md)**, which ships with the addon so it is
there however you installed it.

## This repository

It uses the layout the [Godot Asset Library](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html) expects, so it is both the addon and a
project you can open and edit it in:

```
project.godot                 the demo project, which is this repository
addons/tcps/                  the addon itself
addons/3d_player_controller/  what the demo rides as
addons/controls/              the on-screen input hints
addons/gut/                   the test runner
```

Clone it, open `project.godot` in Godot, and run the demo scene. The addon is mounted at
`res://addons/tcps/` exactly as it is in a game, so it is edited in place with nothing copied
anywhere first. Installing through the Asset Library takes `addons/` and skips the root
`project.godot` as a conflict, which is why that file can live here harmlessly.

## Filming and measuring the board

Two scripts in `tools/` put numbers and pictures on how the board plays, so a change to the feel is checked
rather than argued about. Neither is a test; both use the demo skate park.

```powershell
# Film a scripted run: an autopilot presses the real actions, Godot's movie writer draws every frame at 60 fps
& 'C:\Godot\godot.exe' --path . --write-movie run.avi --fixed-fps 60 -s tools/record_run.gd

# Print the push, coast, ollie, turn and quarter pipe numbers as JSON
& 'C:\Godot\godot.exe' --headless --path . -s tools/measure_run.gd

# Trace one leg of the run headless, no film: start at leg 25 with the rider at leg 24's target, printing the
# board's state, position, velocity and vert wall every tick
$env:TCPS_FIRST_LEG = 25; $env:TCPS_TRACE = 1
& 'C:\Godot\godot.exe' --headless --path . -s tools/record_run.gd
```

The run's legs are the list at the top of `tools/record_run.gd`: a target to steer at, and what to do on the way
(an ollie at an x, a flip, a grab, a spin, a grind, a lip trick, a spine transfer, an acid drop, a wallplant, a walk off the board and back on).
A crouched push turns with a four metre radius, so a leg that must arrive at a ramp square needs a straight run-in
from the leg before it, and a tap's pop comes a third of a second (four and a half metres) after the tap.

`docs/feel_review.md` is the review made with them against Tony Hawk's Underground, and
`docs/thug_skater_reference.md` is the digest of THUG's skater code it compares against.

## Textures import Lossless

Every texture here imports with `compress/mode=0` (Lossless) and `detect_3d/compress_to=1`, so the
editor promotes one to VRAM Compressed the first time it sees it used in 3D. That is Godot's own
default.

This repository used to force `compress/mode=1` (Lossy) with promotion disabled, project wide. That
re-encoded every image through WebP at quality 0.7 before Godot saw it, and still uploaded
uncompressed to VRAM, so it lost real data and bought nothing at run time. It existed only to
squeeze a built `.pck` under GitHub's 100 MB limit, and nothing built is committed any more.

`python ../godot-3d-player-controller-v3/tools/texture_import_policy.py --root .` puts the
repository back on that policy, and `--check` reports without writing.

## Installing it in a game

Copy `addons/tcps/` into your project's `addons/`. See the
[addon's README](addons/tcps/README.md) for what it needs and how to use it.
