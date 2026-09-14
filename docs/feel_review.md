# How TCPS plays against Tony Hawk's Underground

A review of the board as shipped (commit `08527d3`), made by filming it, measuring it and comparing both with
THUG's skater code and footage. The two tools it used ship in `tools/` so the numbers can be rerun after any
change:

- `tools/record_run.gd` drives the rider through the skate park with an autopilot pressing the real actions,
  under Godot's movie writer: `godot --path . --write-movie run.avi --fixed-fps 60 -s tools/record_run.gd`.
  The film was cut into one-frame-per-second contact sheets and six-frames-per-second strips with ffmpeg.
- `tools/measure_run.gd` prints the push, coast, ollie, turn and quarter pipe numbers as JSON, headless:
  `godot --headless --path . -s tools/measure_run.gd`.

The reference is the THUG source (`thug1src/thug` on GitHub, read in full for the skater; the digest is in
`docs/thug_skater_reference.md`) and three minutes of 60 fps PC gameplay (YouTube `ItyI4-yagcU`, 20:00 to
23:00) cut the same way. THUG works in inches and seconds; 1 m is 39.37 in.

## What the film shows

- The rider jams against any wall it meets. Twice in a 73 s run it sat pinned to the side of a ramp for 7 s
  and 12 s, sliding slowly, with the camera inside the geometry. THUG bounces off walls with an angle-scaled
  speed loss, or turns the contact into a wall push, wall plant or wall ride; it never pins the skater.
- Vert works: up the quarter pipe, held in the wall's plane, back down onto the wall. It is the one part that
  follows THUG's code and it reads as such.
- Nothing else that makes THUG happens, because none of it exists: no rails or grinds, no manuals, no flip,
  grab or lip tricks, no balance meter, no revert, no spine transfer or acid drop, no wall ride or wall plant,
  no bail, no score. The 80 m concrete slab has three ramps and no ledge, rail or bench to grind.
- The camera hugs the rider and looks along the board. THUG sits farther back and lower, so the skater is
  small in frame and the ground ahead is what fills it; it tilts up 20 degrees in the air, parks overhead in
  vert air, and zooms in on grinds.

## Measured

| Measure | TCPS (measure_run) | THUG (source, footage) |
| --- | --- | --- |
| Push | 0 to 6 m/s in 0.5 s, cap of 10 m/s at 1.0 s; holding Up is a constant 12 m/s^2 | Continuous kick acceleration while Square is held or autokick is on, up to a kick cap, soft cap with heavy drag and a hard cap around 28 m/s at full stats; no impulse per push |
| Coast | 10 to 6 m/s in 4 s (1 m/s^2 rolling resistance) | No friction at all with autokick off; quadratic wind drag and a rolling term otherwise |
| Flat ollie at top speed | 0.83 s air, 1.02 m peak, speed kept | About 0.65 s air in footage (19 frames at 30 fps); height is a linear function of how long X was held, with separate minimum, maximum, vert and boneless ranges |
| Turn at top speed | 47 deg/s, eased, slower the faster you go | Constant rate whatever the speed; Down adds a sharp turn; velocity is rotated with the facing so the board never slides |
| Quarter pipe (3.3 m wall) at 10 m/s | 1.5 s air, 5.0 m peak (1.7 m over the coping), 5.1 m/s kept after landing (half lost) | Velocity is rotated, not projected, into the wall's plane on the way up and rotated back on the way down, so speed is kept; gravity divided by the hang stat |
| Wall head-on | Pinned, speed bled to zero, camera clipped | Bounce with speed scaled by angle (head-on stops), or wall push, wall plant, wall ride |
| Landing | Turns the model to the roll direction | Velocity projected onto the plane, matrix snapped to the normal; physics never refuses a landing, the script decides sloppy or bail from pitch and spin |

## Why it does not feel like THUG

1. The three things that carry the feel are missing entirely: grinds (air-only, Triangle held, a generous
   snap with an 8x bias toward rails you are parallel to, a speed boost on lock, automatic corners and
   rail-to-rail), the shared balance model for manuals, grinds and lips, and the trick layer (flip, grab,
   revert, spin counting) with a score.
2. Ground handling is a car, not a board. THUG turns at a constant rate and rotates the velocity with the
   facing every frame (`remove_sideways_velocity`); TCPS eases the turn and slows it with speed, and keeps a
   tenth of the sideways velocity.
3. Walls are collisions, not moves. THUG's `bounce_off_wall`, wall push, wall plant and wall ride are what a
   player does when they meet a wall at speed.
4. The ollie is a fixed pop. THUG's is charged: height is linear in hold time up to `skater_max_tense_time`,
   and a downward velocity is discarded first so jumps down a slope are not stolen.
5. Speed is capped low and bled fast. THUG runs to about 28 m/s with no rolling friction when autokick is on,
   which is where the sense of speed comes from; TCPS caps at 10 m/s and loses a metre a second coasting.
6. The camera is a chase camera. THUG's takes its forward from the velocity flattened 80 percent against
   the ground, lags a tripod behind the skater with separate XZ and Y rates, aims it at the true position so
   the lag reads as distance, tilts up in the air, zooms in on grinds and looks straight down in vert air.

## Recommendation

Rewrite the board around THUG's state machine (GROUND, AIR, RAIL, LIP, WALL, WALLPLANT), keeping the two
things that work and are TCPS's own: the rideable contract with the Player, and the granted hand-off over the
network. The rest is written to `docs/thug_skater_reference.md`, which names the formula and the tunable for
every behaviour; the tunables' values are not in the source (`physics.q` is data), so they are set by feel and
against the footage, with `tools/measure_run.gd` as the check.

The rewrite in order of what it buys:

1. Ground and air on THUG's rules: rotate-not-project velocity, constant-rate turning with the velocity
   turned, charged ollie, wall bounce, ground snap rules and the curb snap-up. This is the part every second
   of play touches.
2. Rails: a `Rail` node (a `Curve3D` with sides and a leave angle), the air-only sweep with `Rail_Max_Snap`
   and the parallel bias, lock-on with the speed boost, rail gravity, corners and rail-to-rail; the skate
   park gets ledges, a bench and a handrail.
3. The balance model shared by manuals, grinds and lips, with a meter on the HUD.
4. The trick layer: an input buffer, flip and grab tricks named on the HUD, spin counting, revert, score
   and multiplier, bail from a script-side landing rule.
5. The camera ported from `SkaterCameraComponent`: velocity forward, lagging tripod, air tilt, vert cam,
   grind and big-air zoom, angular limiter.
6. Wall ride and wall plant, spine transfer and acid drop.

Two things the review does not settle and that are the author's to decide: whether to rewrite in place
(replace `skateboard.gd` and keep the scene, the sounds and the network code) or beside it, and whether the
first pass stops at 1 to 3 (ground, air, rails, balance) or goes through the trick layer before it is tried.

## After the first pass (commit `5f80c1f`)

The board was rewritten in place around THUG's state machine with ground, air, rails and balance; the trick
layer, lip tricks, walls beyond the bounce, transfers and the camera port are still to come. The same tools,
run again:

| Measure | Before | After |
| --- | --- | --- |
| Push | 0 to 10 m/s in 1.0 s, 12 m/s^2 | 0 to 12 m/s in 2.5 s, a steady 6 m/s^2 kick to the kick cap |
| Coast, 4 s from 10 m/s | 6.0 m/s | 8.6 m/s (wind only, no rolling friction) |
| Flat ollie, tapped | 0.83 s, 1.02 m (one fixed pop) | 0.50 s, 0.37 m |
| Flat ollie, held half a second | same as tapped | 0.82 s, 0.99 m |
| Turn at top speed | 47 deg/s, eased | 66 deg/s, constant, speed kept, velocity along the facing |
| Quarter pipe air | 1.5 s, 5.0 m, 5.1 m/s kept | 1.6 s, 5.4 m, 6.75 m/s kept |
| Wall head-on | pinned, camera in the wall | stopped by the bounce, turned along it on a glance, never pinned |
| Ledge grind, nobody balancing | no rails | taken 0.05 s after arrival at 7.0 m/s (6 plus the boost), 1.0 s on the rail before the meter bailed |

The autopilot film of the same run is in the review's history; the rider now ollies onto the ledge's front
rail and the bench, grinds them, manuals across the flat, and glances off the wall instead of sitting in it.

## After the camera and the real numbers (commit `HEAD`)

The camera is now THUG's `CSkaterCameraComponent` (`skateboard_camera.gd`), and every tunable in the board,
the balance and the camera is the value from THUG's own `physics.q`, found decompiled at
`atljp/thps-modding-resources` and tabled in `docs/thug_skater_reference.md`. Measured again:

| Measure | THUG's number | Here |
| --- | --- | --- |
| Standing push | 664 in/s^2 to 445 in/s | 16.9 m/s^2, 11.3 m/s reached in 1.0 s |
| Coast, 4 s from 10 m/s | wind 0.00001 f | 5.1 m/s left: the wind is real in THUG |
| Ollie, tapped / held | 350 / 432 in/s pop at 1350 in/s^2 | 0.50 s and 1.1 m / 0.62 s and 1.7 m; THUG's footage showed about 0.65 s |
| Turn at top speed | 1.8 rad/s | 102 deg/s, constant, speed kept |
| Quarter pipe at a crouched push | 15.3 m/s into the wall | 0.7 s air, 1.1 m over the coping, 11.5 m/s kept on landing, back onto the same wall |
| Ledge grind | 40 in snap, 150 in/s boost | taken 0.05 s after arrival |

Two things the numbers forced. The demo's 3.3 m half pipe is taller than THUG's ramps for a standing push,
which tops out at 11.3 m/s, so the crouched push (sprint, THUG's held X) is what reaches its coping; and a
board leaving the top of a wall now does so by THUG's `Ground_stick_angle` rule rather than by the body
sliding round the coping onto the deck. The film shows the camera pitching up the transition, going overhead
in vert air and swinging back behind on landing.

## The trick layer

Flips and grabs in the air named by the direction held, grinds named the same way, manuals, spins counted on
landing with THUG's 60 degree slop, reverts on a vert landing, and the combo (points times count) banked on a
clean landing and lost in a bail, all on the board's HUD as THUG shows it. The remaining gaps to THUG are the
special meter and special tricks, lip tricks, wall rides and wall plants, and the transfers.

## Lips, walls and transfers

Lip tricks on any coping rail (the half pipe's and the quarter pipe's copings and the spine's two are rails now),
wall rides and wallplants on the concrete wall, spine transfers over the new spine and acid drops off the quarter
pipe's deck, which the new bank behind it leads up to; the lip camera drops into the pipe and looks up, and a
trick in vert air zooms the camera in. What is left of THUG's skater is the special meter and its tricks,
skitching, and getting off the board to walk.

## The score and the special meter

Every trick's points are now THUG's own, read from its trick scripts, and the score works as its Score module
does: a spin multiplies the trick it is on, a trick repeated in the run depreciates, time on a grind or a manual
earns nothing, and the special meter fills as the combo grows, lights at three thousand, lifts every stat by three
and opens the created skater's three special tricks. Nothing in the scoring is a guess any more; what is left of
THUG's skater is skitching, walking, and the rest of its trick list.

## Walking

THUG's get-off button now leaves the board in the skater's hand, banks the combo and keeps the run's score, and
the same button gets back on anywhere, the air included; a spine button on foot jumps onto the board for an acid
drop. The walking is the Player's own. What is left of THUG's skater is skitching and the rest of its trick list.
