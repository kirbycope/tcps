![Preview](./assets/tcps.png)

# Tim Cope's Pro Skater (TCPS) for Godot 4.8+

Skateboarding for the [3D Player Controller](../3d_player_controller/README.md): a rideable board with the ground, air, vert, grind and balance physics of Neversoft's Tony Hawk's Underground source and the THPS camera. The board owns the movement, the sounds and the camera; the Player lends its body, its input and its animations through the controller's `Riding` state, which makes the board's camera current and turns the Player's step-up ray off while the board owns the ground. The board touches no Player flags and no Player UI.

> [!NOTE]
> Requires `addons/3d_player_controller` (the `Player`, its `Riding` state and the skateboarding animation clips in `player.tscn`) and, through it, [`addons/controls`](https://github.com/kirbycope/godot-controls), which is where `ActionPrompt` and the on-screen button hints live. `Skateboard` and `SkateboardCamera` register their class names on their own; enabling the plugin only adds the board to the Create New Node dialog.

---

## Interactive Demo Scene

Open and run **`res://addons/tcps/scenes/skate_park.tscn`**. The Player starts on the board (the scene's `MountTimer` calls the pickup board's `equip()` after 0.3 s). Hold Up to push and Down to brake or turn sharp; hold Ollie and let go to pop (the longer the hold, the higher); hold Grind in the air over the ledge, the bench or the handrail and balance with Left/Right; tap Up then Down for a manual (Down then Up for a nose manual) and balance with Up/Down; let go of push on a transition to go vert, or hold it at the lip to fly over the deck; K steps off.

| Node | What it is |
|---|---|
| `Ground` (`CSGBox3D`, group `CONCRETE`) | The flat park floor; the group picks the concrete roll sound. |
| `HalfPipe/LeftTransition`, `RightTransition` (`CSGPolygon3D`, group `WOOD`) | A 3 m radius quarter circle in 3 degree facets with 0.3 m of vert and a 2 m deck, extruded 8 m; the right one is the same polygon rotated 180 degrees. `LeftCoping` / `RightCoping` are decorative, `Flat` is the plywood between them. |
| `QuarterPipe`, `Funbox` (`CSGPolygon3D`, group `WOOD`) | A lone transition and a kicker with a table top. |
| `Ledge`, `Bench` (`CSGBox3D`) and `Handrail` (three `CSGCylinder3D`) | Things to grind. Each carries `Rail` children (`Path3D` with `rail.gd`) along its grindable edges: both long edges of the ledge and the bench, the top of the handrail. |
| `Wall` (`CSGBox3D`, group `CONCRETE`) | A slab to bounce off. |
| `Player` | `player.tscn`, nothing to set. |
| `Skateboard` | The pickup board (`skateboard.tscn`); `skate_park.gd` equips it through the same path the prompt uses. |

---

## Playing the demo

This repository is private, and GitHub Pages will not serve a private repository on this plan, so there is
no published demo. This repository is the project one is built from: it uses the layout the
[Godot Asset Library](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html)
expects, with the addon at `addons/tcps/` and a `project.godot` at the root, so cloning it and
opening it in Godot is all it takes. The addon is edited in place, with nothing copied first.

The player controller and the Controls addon sit under `addons/` beside it, which is what the
recursive clone below is for.

The player controller and the Controls addon are submodules of `addons/`, which is what the second line
fills in.

---

## How to Use

| Node | Where it goes | Set in the Inspector |
|---|---|---|
| `Skateboard` (instance `scenes/skateboard.tscn`) | On the ground anywhere in your level | Nothing required; the surface groups `WOOD`, `STONE` / `COBBLESTONE` and `CONCRETE` on your floors pick the roll sounds |
| `SkateboardCamera` (inside `skateboard.tscn`) | Nothing to add | `behind`, `above`, `tilt`, `field_of_view`, the per-sixtieth `slerp` and `lerp` fractions (plain, vert air, landed), `grind_zoom`, `lookaround_max` |
| `Rail` (a `Path3D` with `scripts/rail.gd`) | Along any edge the board should grind, as a child of the ledge or rail it belongs to, with the curve's points on the edge | `speed_boost` (m/s added on locking on), `leave_angle_degrees` (a sharper bend ends the rail) |

Looking at the board and pressing Action mounts it: `Skateboard.equip()` calls `Player.mount()`, the `Riding` state calls back `mount(player)`, and from then on the board's `ride(player, delta)` moves the Player every physics tick (it drives the `CharacterBody3D` and the Player's movement API: velocity, floor settings, `orientation`, `model_pitch`, the model turn helpers and `update_movement_and_rotation`), `ride_input(player, event)` handles the ollie (charged on press, popped on release), the grind button, the kick push, the manual taps and the dismount through the board's own action exports (resolved for the `input_type` the state keeps current), and `camera` is the current camera. `state` says which of THUG's states the skater is in (`GROUND`, `AIR`, `RAIL`), `trick` and `balance` which balance trick is on, and `trick_started` / `trick_ended(kind, bailed)` say when one begins and ends. The `HUD/BalanceMeter` in `skateboard.tscn` shows the meter to the rider while one runs. K (or D-pad Down) calls `Player.dismount()`; the board is left where the skater stands and the Player's own camera returns. `get_contextual_controls(input_type)` names the labels (`"joypad_button_3": "Ollie"`), and the board's `GroundRay` picks the roll sound.

Animations are the Player's: the board asks for them through `locomotion_requested("SkateboardingLocomotion" / "SkateboardingKickPush")`, `locomotion_blend_requested`, and `jump_requested`, which the `Riding` state connects to the Player's AnimationTree.

Over the network the board is one node in the world on every peer, and its `BodySynchronizer` (`resources/skateboard_replication.tres`) carries its position, rotation and `rider_peer`, the peer whose Player is on it (0 when it is free). Getting on asks the server to put the board under the rider's model on every peer and then hand it to the rider's peer, in that order, so the rider's copy starts sending its place only once everybody has it under their feet; getting off does the same back to the parent it stood under and to the server. A rider who drops out is handed back by every peer on its own, and a board another peer is riding refuses a second rider. Offline there is nobody to ask and the hand-off is immediate.

---

## Physics and camera

Ported from the THUG source at https://github.com/thug1src/thug, state by state; `docs/thug_skater_reference.md` in the repository is the digest of the skater code, with the THUG symbol behind every tunable and, in its table of `physics.q` values, the numbers the game ships with (from the decompiled scripts at https://github.com/atljp/thps-modding-resources). The constants at the top of `skateboard.gd`, `skate_balance.gd` and `skateboard_camera.gd` are those numbers turned from inches, feet and milliseconds into metres and seconds, at the middle of each stat range: gravity is THUG's 3.5 g in the air, a full ollie pops at 11 m/s, a standing push reaches 11.3 m/s and a crouched one (sprint) 15.3, the ground turns at 1.8 radians a second, a rail is taken from a metre away with 3.8 m/s added. THUG's own 8 to 12 ft vert ramps are what a standing push clears; the demo's 3.3 m half pipe wants the crouched push.

- **Ground** (`do_on_ground_physics`): every tick the velocity is rotated into the surface with its speed kept (`RotateToPlane`, never a projection), gravity along the surface slows a climb, and the board never slides: a turn rotates the velocity with the facing at a constant rate whatever the speed (sharper with Down), the speed is put back along the facing (`remove_sideways_velocity`), and rolling backwards turns the skater round. A kick (Up) is a steady acceleration to a cap, Down brakes, and the only friction is the wind, quadratic in speed and heavy above the soft cap. A wall is bounced off (`bounce_off_wall`): the board runs along it and loses speed by how square-on the hit was, to nothing head-on.
- **Ollie** (`do_jump`): charged while the button is down and popped when it comes up, its speed linear in the hold up to half a second, a downward speed thrown away first; a smaller range off vert; off a rail it leaves the rail.
- **Air** (`do_in_air_physics`): Left/Right spin once held past a tap, then ramp to full rate; leaving a wall steeper than 50 degrees is a vert launch, with the velocity rotated into the wall's vertical plane and the skater held in that plane while the wall is still behind them, coming back down onto it; holding forward at the lip breaks vert and flies over the deck; a landing turns the skater to face the way they roll.
- **Rails** (`CRailManager::StickToRail`, `got_rail`, `do_rail_physics`): looked for only in the air with Grind held, along the tick's move, within `RAIL_MAX_SNAP`, with a rail the board travels along scoring eight times better than one across it. Locking on puts the horizontal speed along the rail plus the rail's boost; gravity along the rail speeds a descent and turns a stall round; the rail ends at its last point or a bend past its leave angle, and an ollie leaves it. No rail is taken again for a moment after leaving one.
- **Balance** (`CManual`, `SkateBalance`): one model for manuals and grinds. The needle leans further the further it leans, faster the longer the trick lasts; the buttons push it back (Left/Right on a rail, Up/Down in a manual); left alone it drifts and never rests; off either end is a bail, which takes most of the speed and the controls for a moment.
- **Camera** (`CSkaterCameraComponent::Update`): runs in the physics tick after the board has moved the skater. A target frame is built from the way the skater travels (the velocity, flattened four fifths against the ground and fully in the air) and the skater's up (the smoothed ground normal, so the view pitches up a transition with them; world up in plain air), tilted down a little and twenty degrees more in the air; the camera's frame turns toward it by a fixed fraction per sixtieth of a second (`slerp`, corrected for the frame rate the way THUG's `GetTimeAdjustedSlerp` does) with a limiter on how far it may swing in one frame; a tripod lags the skater by `lerp_xz` and `lerp_y`; the camera sits `behind` the frame and `above` the skater from the tripod and is aimed at the true skater, so the lag reads as distance. In vert air the forward is straight down, the tripod rides on the skater and the frame's up is the wall's normal, so the camera goes overhead with them and watches them come back down the same wall, then swings back behind them faster for ten frames after the landing. On a rail it zooms to `grind_zoom` and rolls with the balance. A ray from the focus and two side feelers keep it out of walls. `field_of_view` is vertical, 55 degrees for THUG's 72 horizontal.

Not yet ported: lip tricks, wall rides and wall plants, spine transfers and acid drops, flip and grab tricks, spin counting, reverts and the score, and the camera's big-air zoom, which needs the tricks.

---

## Tests

```powershell
& 'C:\Godot\godot.exe' --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://addons/tcps/tests -gexit
```

---

## Assets

| Folder | Source | License |
|---|---|---|
| `assets/sketchfab/skateboard/` | [Skateboard by Jamoues](https://sketchfab.com/3d-models/skateboard-0f7b8ea366654674b217a743959798e7) | CC BY 4.0 |
| `assets/gravitysound/Skateboard SFX/` | [Gravity Sound](https://gravity-sound.itch.io/) | Not recorded - fill in |

---

## License

MIT, see the repository LICENSE.
