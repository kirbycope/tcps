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

## Installing it in a game

Copy `addons/tcps/` into your project's `addons/`. See the
[addon's README](addons/tcps/README.md) for what it needs and how to use it.
