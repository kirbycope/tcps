# How THUG's skater moves: an engineering description from the source

Read from the Tony Hawk's Underground (2003, Neversoft) source at `thug1src/thug` on GitHub, which holds
only `Code/`. `physics.q`, the script file holding nearly every tunable, is not in that tree, but the
decompiled game scripts are on GitHub at `atljp/thps-modding-resources` under
`Scripts/THUG/THUG_qb.pre_(decompiled_roq)/game/skater/physics.txt`, and the values the board uses are listed
in the section "The physics.q values" below. Wherever a value lives there, the symbol is named exactly as the
C++ reads it (`GetPhysicsFloat(CRCD(..., "Name"))`). Hard-coded numbers are quoted with file and line. Line
numbers refer to `Code/Sk/Components/SkaterCorePhysicsComponent.cpp` unless another file is named.

## The physics.q values

Inches, inches per second, radians per second and milliseconds, as the C++ reads them. A `stat` range is
`(stat 0, stat 10)`; the board takes the middle. Gravity is negative in the file (down).

| Symbol | Value |
|---|---|
| `Physics_Ground_Rotation` / `Physics_Ground_Sharp_Rotation` | 1.8 / 3.6 rad/s |
| `Physics_Standing_Acceleration_Stat` / `Physics_Crouching_Acceleration_stat` | 629..700 / 1057..1200 in/s^2 |
| `Skater_Max_Standing_Kick_Speed_Stat` / `Skater_Max_Crouched_Kick_Speed_Stat` | 394..496 / 532..675 in/s |
| `Skater_Max_Speed_Stat` / `Skater_Max_Max_Speed_Stat` | 757..900 / 957..1100 in/s |
| `Physics_Standing_Air_Friction` / `Physics_Crouched_Air_Friction` / `Physics_Heavy_Air_Friction` | 0.00001 / 0.000002 / 0.0001 |
| `Physics_Rolling_Friction` | 0.00001 |
| `Physics_Brake_Acceleration` | 900 in/s^2 |
| `Physics_Ground_Gravity` / `Physics_Air_Gravity` / `Physics_Rail_Gravity` / `Wall_Ride_Gravity` | 1000 / 1350 / 2000 / 969 in/s^2 |
| `Physics_Air_hang_Stat` / `Physics_Vert_hang_Stat` | 1.0 / 1.1 |
| `Physics_Jump_Speed_min_Stat` / `Physics_Jump_Speed_Stat` | 350 / 414..450 in/s |
| `Physics_Air_Jump_Speed_min_Stat` / `Physics_Air_Jump_Speed_Stat` | 100 / 275 in/s |
| `Physics_Boneless_Jump_Speed_min_Stat` / `Physics_Boneless_Jump_Speed_Stat` | 400 / 489..525 in/s |
| `Skater_max_tense_time` | 200 ms |
| `Physics_Air_Rotation_stat` / `Physics_air_tap_turn_speed_stat` | 6.85..7.75 rad/s |
| `Physics_Air_No_Rotate_Time` / `Physics_Air_Ramp_Rotate_Time` | 100 / 50 ms |
| `Physics_Air_Lean_stat`, `Physics_Air_No_Lean_Time`, `Physics_Air_Ramp_Lean_Time` | 1.0 rad/s, 200 ms, 200 ms |
| `Skater_autoturn_speed` / `skater_autoturn_cancel_time` / `skater_autoturn_vert_angle` | 3.0 rad/s / 300 ms / 5 deg |
| `Ground_stick_angle` / `Ground_stick_angle_forward` | 30 / 60 deg |
| `Physics_Ground_Snap_Up` / `Physics_Ground_Snap_Down` / `Physics_Air_Snap_Up` | 13 / 8.2 / 15 in |
| `Normal_Lerp_Speed` | 0.1 per frame |
| `Skater_Flip_Speed` | 1 in/s |
| `Skater_Vert_Allow_break_Time` / `Skater_vert_push_time` / `Skater_vert_active_up_time` | 200 / 130 / 250 ms |
| `physics_break_air_speed_scale` / `physics_break_air_up_scale` / `Skater_Break_Vert_forward_tilt` | 0.75 / 0.75 / 45 deg |
| `Physics_Vert_Push_Out` | 3 in |
| `Rail_Max_Snap` / `Rail_Speed_Boost` / `Point_Rail_Speed_Boost` | 40 in / 150 / 100 in/s |
| `Rail_Corner_Leave_Angle` / `Rail_Jump_Angle` / `Rail_Tolerance` | 50 deg / 15 deg / 0.7 |
| `Rail_minimum_rerail_time` / `Rail_jump_rerail_time` / `Rail_walk_rerail_time` | 500 / 300 / 1000 ms |
| `Wall_Bounce_Angle_Multiplier` / `Wall_Bounce_Dont_Slow_Angle` / `Wall_Non_Skatable_Angle` | 1.1 / 30 deg / 25 deg |
| `Wall_Ride_Min_Speed`, `_Max_Incident_Angle`, `_Max_Tilt`, `_Turn_Speed`, `_Jump_Out_Speed`, `_Jump_Up_Speed` | 75 in/s, 60 deg, 68.5 deg, 0.004 rad/frame, 40, 80 in/s |
| `Physics_Wallplant_*` | approach 20 deg, speed loss 225, min exit 200, vertical exit 500 in/s, min height 24 in, distance 27.6 in, duration 160 ms |
| `ManualParams` | `Lean_Gravity_Stat` 0.02, `Instable_Rate` 0.099..0.07, `Instable_Base` 1, `Lean_Min_Speed` 5, `Lean_Rnd_Speed` 20, `Lean_Acc` 10 (x 0.75..1.0 by difficulty), `Lean_Bail_Angle` 4000, `Cheese` 700 over 100 frames, `Repeat_Multiplier` 0.25, `Lean_Repeat_Multiplier` 0.8; lean in 4096ths, rates per frame |
| `GrindParams` | as the manual but `Instable_Rate` 0.104..0.09, `Lean_Rnd_Speed` 7.07..6, `Cheese` 2500 over 30 frames, `Repeat_Multiplier` 0.31..0.1, `Same_Grind_Add_Time` 2 s, `New_Grind_Sub_Time` -0.286..0 |
| `LipParams` | `Instable_Rate` 0.5..0.2, `Lean_Min_Speed` 10, `Lean_Rnd_Speed` 20, `Cheese` 3000..1000 over 180 frames |
| `BalanceSafeButtonPeriod` / `BalanceIgnoreButtonPeriod` | 1000 / 0 ms |
| `Skater_Camera_Standard_Medium` | `horiz_fov` 72, `behind` 12 ft, `above` 4.3 ft, `tilt` 0.18, `slerp` 0.04, `vert_air_slerp` 0.04, `vert_air_landed_slerp` 0.375, `lerp_xz` 0.25, `lerp_y` 0.75, vert lerps 1.0, `zoom_lerp` 0.0625, `big_air_trick_zoom` 0.7, `grind_zoom` 1.0, `lip_trick_tilt` -0.8, `lip_trick_above` 0.4, `origin_offset` 0.2. Near: behind 7, above 2, slerp 0.08, vert 0.025. Far: behind 14, above 6, tilt 0.3, slerp 0.08 |

Conventions:

- **Units are inches and seconds.** `FEET(x)` converts feet to inches. The `SetSpeed` script command
  documents "speed in inches per second ... The skater's max speed is about 1100 inches per second (depends
  on stats)" (`:640`). Timestamps (`Tmr::Time`, `GetPressedTime()`) are milliseconds.
- `m_matrix`: `[X]` right, `[Y]` up (surface normal when grounded), `[Z]` forward (facing; not necessarily
  the velocity direction). `m_vel` world velocity in in/s; `m_pos` the contact point; `m_old_pos` frame start.
- `Mth::Vector::RotateToPlane(n)` is **length-preserving** (project, then renormalize to the original
  length, `Core/Math/vector.cpp:141`). `ProjectToPlane(n)` drops the normal component and loses speed. THUG
  uses `RotateToPlane` wherever it wants speed kept through a transition; this is a large part of the feel.
- Stats: `GetScriptedStat(name)` reads a structure `{ (lo, hi) stat_index [switch (a,b)] [diff (a,b)]
  [limit] }` and returns `lo + (hi - lo) * stat / 10` (`skater.cpp:617-706`). The stat is 0..10 from the
  profile, **+3 while the special meter is lit** (`skater.cpp:592`), forced to 10 in net games. Every
  `*_stat` tunable is a range, so Special makes you faster, jump higher and spin faster.

## 1. State machine

`EStateType` (`skaterflags.h`): `GROUND, AIR, WALL, LIP, RAIL, WALLPLANT`. Skating vs walking is an outer
switch in `CSkaterPhysicsControlComponent` that suspends the whole skate chain when walking.

Per-frame pipeline for one skater (component order `skater.cpp:1095-1180`): SkaterState, Input,
SkaterScore, MatrixQueries, Trick, PhysicsControl, **CorePhysics**, Rotate, Gap, AdjustPhysics, Trigger,
FinalizePhysics, CleanupState, Walk, ..., BalanceTrick, ..., MovableContact. Cameras are separate objects
updated after the skater.

`CSkaterCorePhysicsComponent::Update()` (`:178-262`):

```
m_frame_length = Tmr::FrameLength()
m_landed_this_frame = false
handle_tensing()              // X pressed and not TENSE -> set TENSE (timestamped)
limit_speed()                 // section 2
clear SNAPPED_OVER_CURB, SNAPPED (one-frame camera flags)
switch (state):
  GROUND:    m_last_ground_pos = pos; do_on_ground_physics(); maybe_skitch();
  AIR:       do_in_air_physics(); if now GROUND -> m_landed_this_frame = true
  WALL:      do_wallride_physics()
  LIP:       do_lip_physics()
  RAIL:      do_rail_physics()
  WALLPLANT: do_wallplant_physics()
handle_post_transfer_limit_overrides()
maybe_stick_to_rail()         // rail search EVERY frame in AIR with Triangle held
update_special_friction_index()
```

Then `CSkaterRotateComponent` (script `Rotate x/y/z Duration=`: applies `angle/duration * dt` per frame
about a local axis to physics and display matrices), `CSkaterAdjustPhysicsComponent` ("uber frig": ray from
`pos + 8 in` down 400 ft; records `m_height`; lifts the skater to +0.001 in if below ground; if no ground at
all, restores `m_safe_pos` + a tiny nudge, negates velocity, forces any non-GROUND/AIR state to AIR; stores
`m_old_pos = m_pos`), `CSkaterFinalizePhysicsComponent` (orthonormalizes, publishes
`m_lerping_display_matrix` for rendering and the camera normals, computes `mJumpedOutOfLipTrick` = left
LIP into AIR with |vx|,|vz| < 1).

Transitions:

| From | To | Where | Condition |
|---|---|---|---|
| GROUND | AIR | `snap_to_ground` `:2680` | no skatable ground in snap range or angle change beyond `Ground_stick_angle`; event `GroundGone` |
| GROUND | AIR | `do_jump` (script `Jump`) | X released after TENSE (`maybe_flag_ollie_exception` fires `Ollied`) |
| AIR | GROUND | `do_in_air_physics` `:5182` | movement segment hits a skatable face; event `Landed` |
| AIR | RAIL / LIP | `maybe_stick_to_rail` -> `got_rail` | Triangle held, rail within `Rail_Max_Snap` |
| AIR | WALL | `check_for_wallride` | wall-ridable face, Triangle in window |
| AIR | WALLPLANT | `check_for_wallplant` | vertical wall, `Wallplant_Trick` input, min height |
| WALL | AIR | `do_wallride_physics` | no wall under feet, ceiling, non-wallable face, or ollie |
| WALL | GROUND / RAIL | `do_wallride_physics` | forward face `normal.y > 0.9` (tries rail first) |
| WALLPLANT | AIR | `do_wallplant_physics` | `Physics_Wallplant_Duration` elapsed |
| RAIL | AIR | `do_rail_physics` / `skate_off_rail` | ollie, rail end, sharp corner, wall ahead, balance bail |
| LIP | AIR | script `SetState`/`Jump` | position restored to `m_pre_lip_pos` on exit |

`SetState` (`:1309`) stamps `m_went_airborne_time` entering AIR (not from WALL) and `m_landed_time` leaving
it, clears the spin tally and L1/R1 triggers entering AIR.

Flags (`skaterflags.h`): `TENSE, FLIPPED, VERT_AIR, TRACKING_VERT, LAST_POLY_WAS_VERT, CAN_BREAK_VERT,
CAN_RERAIL, RAIL_SLIDING, AUTOTURN, IS_BAILING, SPINE_PHYSICS, IN_RECOVERY, SKITCHING, SNAPPED_OVER_CURB,
SNAPPED, IN_ACID_DROP, AIR_ACID_DROP_DISALLOWED, NO_ORIENTATION_CONTROL, NEW_RAIL, OLLIED_FROM_RAIL`.

## 2. Ground (`do_on_ground_physics` `:1498-1780`)

1. Clear vert/air flags; `mp_rail_node = NULL` (touching ground always re-allows re-railing).
2. **`vel.RotateToPlane(m_current_normal)`** if `|vel| > 0.001` (speed-preserving).
3. **Ground gravity**: `g = (0, Physics_Ground_Gravity, 0).ProjectToPlane(normal)`; `vel += g * dt`.
   (`OverrideLimits` can substitute its `gravity` while `vel.y > 0`.)
4. **Brake or kick** (skipped during manual/skitch balance):
   - `is_trying_to_brake()` `:1789`: autokick off, Square up and speed < 50 in/s; or Down held **and**
     (speed < 50, or neither Left nor Right, or moving backwards vs facing).
   - `do_brake()` `:1822`: none on a steep slow slope; if `speed < 2 * Physics_Brake_Acceleration * dt` zero
     it; else `vel += -normalize(vel) * Physics_Brake_Acceleration * dt`.
   - `can_kick()` `:1884`: autokick or Square; Down not held; speed below
     `Skater_Max_Standing_Kick_Speed_Stat` (or `Skater_Max_Crouched_Kick_Speed_Stat` when TENSE).
   - `do_kick()` `:1933`: `vel += facing * accel * dt`, `accel = Physics_Standing_Acceleration_stat` /
     `Physics_crouching_Acceleration_stat`. **No push impulse and no stacking**: pushing is continuous
     acceleration every allowed frame up to the kick cap; the push animation is cosmetic.
5. **Friction** `:1977`: with autokick off, default rolling friction and not bailing, **none at all**.
   Otherwise wind `vel -= normalize(vel) * f * 60 * dt * |vel|^2`, `f = Physics_Crouched_Air_Friction`
   (TENSE) or `Physics_Standing_Air_Friction` (`OverrideLimits` default friction 2.0e-6 gives the magnitude);
   rolling `vel -= normalize(vel) * 60 * m_rolling_friction * dt` (zeroed if it would reverse),
   `m_rolling_friction = Physics_Rolling_Friction`, temporarily replaced by revert `SetSpecialFriction` arrays
   with `Duration`, index stepped down after `Physics_Time_Before_Free_Revert`.
6. `push_away_from_walls` only when a script set `SetExtraPush` (defaults radius 48, speed 100, turn 6).
7. **Steep slow slope** `:1868`: speed < `Skater_max_sloped_turn_speed` and
   `normal.y < Skater_max_sloped_turn_cosine` -> no brake, no rolling friction, facing turned toward the fall
   line at `Skater_Slow_Turn_on_slopes` rad/s.
8. **Move**: `pos += vel * dt`; `handle_forward_collision()`; `snap_to_ground()`. If the move fell short by
   > 0.1 in (curved surface), the remainder is re-applied **once** along the new velocity direction
   (`:1666-1710`) so QP entries keep speed.
9. If still GROUND: `handle_ground_rotation()`, `remove_sideways_velocity()`, `check_side_collisions()`,
   `check_leaning_into_wall()`, `flip_if_skating_backwards()`, `maybe_flag_ollie_exception()`,
   `m_tap_turns = 0`.

**Speed limits** `limit_speed` `:1416` (horizontal only): `> Skater_Max_Max_Speed_Stat` clamp;
`> Skater_Max_Speed_Stat` apply wind resistance with `Physics_Heavy_Air_Friction`. Soft cap plus hard cap;
overrides raise both.

**Turning** `:3911`: Left/Right `rot = +/- Physics_Ground_Rotation` rad/s; with Down
`+/- Physics_Ground_Sharp_Rotation`, ramped linearly over `STOPPED_TURN_RAMP_TIME = 600 ms` (`skater.h:175`)
when speed < 10. `rot *= dt`; **velocity `RotateY(rot)` and matrix `RotateYLocal(rot)` both**. No speed
dependence, no speed loss. `remove_sideways_velocity` `:4005` then forces
`vel = facing * speed * sign(dot(vel, facing))`: the board never slides. `flip_if_skating_backwards` `:4672`:
not bailing/skitching/braking, velocity opposite facing, speed > `Skater_Flip_Speed` -> facing reversed
(X, Z negated).

**Forward collision** `:2368`: feeler `old_pos + up*Skater_First_Forward_Collision_Height` to
`pos + up*h + forward*Skater_First_Forward_Collision_Length` (comments: 10 in, ~8 in). Non-skatable or
`|dot(normal, current_normal)| < 0.01` -> wall, `bounce_off_wall`. Else a QP: `pos = hit + normal * 0.1`.

**Ground snap** `:2524`: feeler `pos + up*Physics_Ground_Snap_Up` to `pos - up*200`. Non-skatable and below
it: `pos = hit + normal`. Skatable: `up_dot = dot(forward rotated into new plane, forward rotated into old
plane)`; allowed change `Ground_stick_angle` deg (`Ground_stick_angle_forward` when Up held; comment says
"like < 60 degrees or so"). If surface faces you and `up_dot < cos(angle)` -> off. Else for a downward snap
`max_drop = max(|last_move| * tan(acos(up_dot)), Physics_Ground_Snap_Down)`; drop bigger than that -> off.
Sticking: `pos = hit`, `new_normal(normal)`, `SNAPPED_OVER_CURB` if moved > 2 in between near-parallel faces
(`up_dot > 0.99`). Off: `SetState(AIR)`, `GroundGone`, `maybe_straight_up()`, `CAN_BREAK_VERT`,
`maybe_break_vert()` (unless spine buttons: then acid drop check).

`new_normal`/`adjust_normal` `:2747-2840`: physics `[Y]` snaps at once; the display normal interpolates at
`Normal_Lerp_Speed * dt * 60` per frame (counter 1->0). Custom parks: a 72 in ray along the new normal
hitting anything forces straight-up.

`check_side_collisions` `:4041`: feelers left/right from `pos + up*Skater_side_collide_height`, length
`Skater_side_collide_length` (+`Skater_air_extra_side_col` in AIR). `|dot(normal, up)| < 0.25` is a wall:
restore `m_safe_pos`, `rotate_away_from_wall(lerp 0.2)`, push out. In AIR this is where `check_for_wallride`
is also tried (`STICKY_WALLRIDES`). `check_leaning_into_wall` `:4600`: below
`Skate_min_wall_lean_push_speed`, a sideways feeler grows with Left/Right hold (`Skate_wall_lean_push_length`,
`_time`, `_height`).

Skatability `:8013`: `mFD_SKATABLE`/`mFD_NOT_SKATABLE` override; `mFD_VERT` skatable; `mFD_WALL_RIDABLE` not
skatable but wallable; else skatable iff `normal.y >= sin(Wall_Non_Skatable_Angle)`.

## 3. Air and the ollie

**Charge/jump** (`:4702`, `do_jump` `:8098`): X press -> `TENSE`. Release -> `m_tense_time` = ms held,
`Ollied` event, script calls `Jump [BonelessHeight]`. `m_tense_time = min(m_tense_time,
skater_max_tense_time)`. Ranges: `Physics_Jump_Speed_min_stat..Physics_Jump_Speed_stat`; from vert
`Physics_air_Jump_Speed_min_stat..Physics_air_Jump_Speed_stat`; boneless
`Physics_Boneless_[air_]Jump_Speed_[min_]stat`. **`jump_speed = lerp(min, max, m_tense_time /
skater_max_tense_time)`.** Then: if `vel.y < 0` set to 0 (nicer jumps down slopes); `vel.y += jump_speed`.
Falling in VERT_AIR instead: `vel += jump_speed * m_display_normal` (push out of the ramp), no vertical add.
Upside down (`matrix[Y].y < -0.1`): `vel.y -= 1.5 * jump_speed`, `pos += up*12`. From RAIL (or AIR right
after RAIL): `ollie_off_rail_rotate` yaws velocity and facing by +/-`Rail_Jump_Angle` deg if Left/Right held.
From GROUND: `maybe_straight_up()`, `CAN_BREAK_VERT`. `SetState(AIR)`, `SkaterJump`.

**Integration** `:4797-4900`: `acc = (0, g, 0)`, `pos += vel*dt + 0.5*acc*dt^2`, `vel += acc*dt`.
`g = Physics_Air_Gravity / Physics_Air_hang_Stat` (normal) or `/ Physics_vert_hang_Stat` (VERT_AIR or
SPINE_PHYSICS); `moon_gravity` cheat multiplier. **No terminal velocity**; only the horizontal caps in
`limit_speed`. During SPINE_PHYSICS the position also moves by constant `m_spine_vel` (shrunk to 0.1 once
below the target height while falling).

**Air control** `handle_air_rotation` `:5370`: L1/R1 `rot = +/- Physics_air_rotation_stat` rad/s, no ramp
(with `m_spin_taps`, a tap queues +/-180 deg served at `Physics_air_tap_turn_speed_stat`). Left/Right: same
rate but hold time `t` ms shaped: 0 while `t <= Physics_Air_No_Rotate_Time`, ramp `(t - no)/(ramp - no)`
until `Physics_Air_Ramp_Rotate_Time` (tapping for flip tricks does not spin). Holding
> `skater_autoturn_cancel_time` cancels autoturn. Disabled by `NO_ORIENTATION_CONTROL` (from walking) and
`NoSpin`. **Autoturn** (vert only): with no manual spin, facing turns toward `m_fall_line` at
`Skater_autoturn_speed` rad/s, finishing exactly; gives up within `skater_autoturn_vert_angle` deg of straight
up and during transfers. `rot *= dt`, both matrices `RotateYLocal`; `mTallyAngles += deg(rot)`; in vert air
the spin only registers once `|tally| >= 360 - spin_count_slop`.

`handle_air_lean` `:5568`: Up/Down `RotateXLocal` at `Physics_air_lean_stat` rad/s with
`Physics_Air_No_Lean_Time`/`Physics_Air_Ramp_Lean_Time` shaping; off in VERT_AIR, transfers, and while
Circle/Square held.

`rotate_upright` `:5755`: unless VERT_AIR/SPINE or a scripted X/Z rotation, roll about forward toward world
up at `skater_upright_sideways_speed` deg/s, dead band `0.02 * dt * 60` on the dot.
`handle_air_vert_recovery` `:5693` (`IN_RECOVERY` or spine buttons): ground 500 in below not vert and
`normal.y >= 0.2` -> drop VERT_AIR, pitch toward upright at `Physics_recover_rate_stat` until
`matrix[Y].y > 0.9`.

**Landing** `:5150-5270`: the segment `old_pos -> pos` hitting a **skatable** face: `pos = hit + normal`;
`SetState(GROUND)`; `mLandedFromVert = m_true_landed_from_vert = (VERT_AIR || SPINE_PHYSICS)`. Velocity:
straight-up jump (`vx == vz == 0`) with Down held -> `vel.y = 0`; else **`vel.ProjectToPlane(normal)`**
(component into the ground is lost; flat landings keep horizontal speed exactly, slope landings keep the
in-plane part); after a transfer/acid drop `RotateToNormal(m_transfer_goal_facing)` then
`RotateToPlane(normal)` (speed kept), floor `Physics_Acid_Drop_Min_Land_Speed`, fallback to projection if it
would point uphill. `ZeroIfShorterThan(10)`. Matrix `[Y] = normal` at once. `Landed` event. **No angle
tolerance, sloppy-landing or bail test exists in C++**; the `Landed` script (missing data) queries
`PitchGreaterThan`, `Flipped`, `LandedFromVert`, `GetSpin`, `Crouched` and picks land/sloppy/bail; bails set
`IS_BAILING` and physics keeps running. Non-skatable hit in air: `vel.RotateToPlane(normal)`, facing into the
plane, `pos += normal * Skater_Min_Distance_To_Wall`.

`check_for_air_snap_up` `:6022`: on any air collision, a feeler from `pos + Physics_Air_Snap_Up` (comment:
15 in) down to `pos` (extended to start height if rising) finds a top face with `normal.y > 0.5` and a clear
line; puts the skater on top. `SNAP_OVER_THIN_WALLS` (rising, upright, near-vertical wall): try
`Physics_Air_Snap_Up`, then step down 2 in until > 4 to minimise the snap. This is curb/fence/ledge pop-over.
`handle_upward_collision_in_air` `:6112`: head feeler `Skater_default_head_height` (6 in for
`Physics_Ignore_Ceilings_After_Wallplant_Duration` after a wallplant) pushes down out of ceilings
(`normal.y < -0.1`) and projects velocity. Late jumps: `maybe_flag_ollie_exception()` also runs in AIR;
transfers/acid drops remove the `Ollied` handler.

## 4. Grinds

**Search** (`maybe_stick_to_rail` `:6561`; `CRailManager::StickToRail` `rail.cpp:994`): runs after state
physics, **only in AIR** (or `override_air` when a wallride lands), not bailing, not `NoRailTricks`,
**Triangle currently held**, > `Physics_Wallplant_Disallow_Grind_Duration` since a wallplant.
`StickToRail(a = old_pos, b = pos)` over world rails then each moving object's rails in local space:

- AABB cull of segments against the movement box expanded by `Rail_Max_Snap` per axis.
- `LineLineIntersect` -> closest points, `dist`.
- `dot = |dot(rail_dir_xz, move_dir_xz)|` (straight up counts as 1).
- **Score `dist * (0.122 + 1 - dot)`** (parallel rails 8x preferred), acceptance
  `dist * (2 - dot) <= Rail_Max_Snap`; a better-scoring-but-too-far rail blocks worse ones. `side` mismatch
  (rail-to-rail only) doubles the score; `min_dot = cos(Rail_Corner_Leave_Angle)` rejects perpendicular
  rails only in custom parks soon after a rail or when continuing. Point rails by perpendicular distance,
  counted double.

`will_take_rail` `:6656`: a different rail (not same segment or neighbours) sets `CAN_RERAIL`; otherwise need
`CAN_RERAIL` or `elapsed(m_rail_time) > m_rerail_time` (`Rail_Minimum_Rerail_Time` after skating off,
`Rail_jump_rerail_time` after an ollie off, `Rail_walk_rerail_time` from walking); not already RAIL; not
tracking vert unless rising.

**Lock-on** `got_rail` `:6710-7225`: line `pos -> rail_pos` may not hit geometry > 6 in from the rail; zero
horizontal velocity -> `vel.xz = facing.xz`; if `|vel.xz| > 10` **`vel.RotateToPlane((0,1,0))`** (all speed
made horizontal, "Oil Rig patch"); `sign = sign(dot(rail_dir, vel))` (random if 0); refuse if the snap point
is the rail end in the travel direction; `pos = rail_pos`, `SetState(RAIL)`; **`old_y = vel.y;
vel.ProjectToNormal(dir); vel.y = old_y; vel += dir * sign * Rail_Speed_Boost`** (points:
`Point_Rail_Speed_Boost`, `Physics_Point_Rail_Kick_Upward_Angle`); side from 2D cross of `dir` with
`rail_pos - m_last_ground_pos` (where you last stood); bad-ledge feelers `Rail_Bad_Ledge_Side_Dist` each side,
`Rail_Bad_Ledge_Drop_Down_Dist` deep; `Rail_Parallel = |dot(dir, right)| < Rail_Tolerance`; `mRail_Backwards`
from the front/right dot; `GrindTrickList[dpad][right|parallel<<1|backwards<<2|regular<<3]` script runs
`DoBalanceTrick Type=Grind`. `m_rail_time = now`.

**Riding** `do_rail_physics` `:7310-7735`: `CAN_RERAIL = false`; ollie -> `Rail_jump_rerail_time`,
`OLLIED_FROM_RAIL`, `pos.y += 1`. Else balance, then **rail gravity** `g = (0, Physics_Rail_Gravity,
0).ProjectToNormal(dir)`, `vel += g*dt` (a sign flip just toggles `mRail_Backwards`). `last_segment` if no
active next node or XZ corner > `Rail_Corner_Leave_Angle`. Overshoot past `segment_length + 0.1` carries onto
the next segment (`pos = node`, `pos += extra_dist * forward`). **Every frame `vel.RotateToNormal(dir);
vel *= sign`** (length kept); `[Z] = dir * (backwards ? -sign : sign)`, `[X]` horizontal-perpendicular,
`[Y]` cross (tilts with sloped rails); display forward lerps 0.3/frame. `pos += vel*dt +
extra_dist*forward`. On the last segment a forward feeler (`movement + 6 in`, raised 1 in) knocks you into
AIR (`OffRail`). `SetGrindTweak` points each frame times the robot-rail multiplier.

**Leaving** `skate_off_rail` `:7762`: search `pos - vel*dt -> pos` (raised 6 / 6.1 in),
`min_dot = cos(Rail_Corner_Leave_Angle)`, current side, for a different rail whose segment contains the point
(`dot(to_start, to_end) < 0`): `vel.RotateToNormal(newdir) * sign`, `pos = rail_pos`, stay in RAIL
(**rail-to-rail without leaving the state**). Else AIR, `pos.y += 1`, `OffRail`.

Generosity comes from: whole-segment sweep plus `Rail_Max_Snap` in all directions every air frame; 8x
parallel bias; rotate-not-project plus `Rail_Speed_Boost`; automatic corners and joins; only Triangle
required, direction and trick inferred.

## 5. Manuals and the balance meter (`manual.cpp`, `SkaterBalanceTrickComponent.cpp`)

One class `CManual`, four instances (`mManual`, `mGrind`, `mLip`, `mSkitch`), started by script
`DoBalanceTrick Type=Manual ButtonA=Up ButtonB=Down` (etc.), stopped by `StopBalanceTrick` or falling off.
Manual **entry is script side** (trick component matches Up,Down / Down,Up from its event queue; windows are
integers in trick definitions via `GetPhysicsInt`, `trickcomponent.cpp:527`). Physics then skips brake/kick
and runs `DoManualPhysics()`. **No manual speed loss in physics**: friction and slope gravity unchanged; you
only lose push and brake.

Params per type struct in physics.q (`ManualParams`, `GrindParams`, `LipParams`, `SkitchParams`), each a
stat range vs the matching balance stat: `Lean_Gravity_Stat, Instable_Rate, Instable_base, Lean_Acc,
Lean_Min_Speed, Lean_Rnd_Speed, Lean_Bail_Angle, Repeat_Min, Repeat_Multiplier, Lean_Repeat_Multiplier,
Cheese, CheeseFrames, Same_Grind_Add_Time, New_Grind_Sub_Time`; globals `BalanceSafeButtonPeriod`,
`BalanceIgnoreButtonPeriod` (ms), `robot_rail_add_time`, `robot_rail_nudge`. Meter shows `-lean / 4096`;
bail at `Lean_Bail_Angle`.

Per frame (`scale(f) = f * dt * 60`):

```
cheese -= scale(Cheese / CheeseFrames)   (floor 0)
mManualTime += dt
instability = Instable_base + mManualTime * Instable_Rate
lean += scale(lean * Lean_Gravity_Stat * instability)   // the more you lean the more you lean
lean += scale(leanDir * instability)
A pressed (after release / BalanceIgnoreButtonPeriod): leanDir -= scale(Lean_Acc) * mult
B pressed:                                              leanDir += scale(Lean_Acc) * mult
neither: |leanDir| < Lean_Min_Speed ? leanDir = rnd(Lean_Rnd_Speed|1) * sign
                                    : leanDir += rnd(50)/100 * sign          // never rests
|lean| > Lean_Bail_Angle -> OffMeterTop/OffMeterBottom, lean = 0, trick type = 0
anim wobble target = (lean + 4096) / 8192
```

`mult` ramps 0..1 over `BalanceSafeButtonPeriod` only when pressing against the lean. `SetUp()`: previous
`leanDir` reused `* Repeat_Multiplier`, floored to `Repeat_Min` (manual falls +, nose manual -, grind
random); `lean *= Lean_Repeat_Multiplier; lean += cheese * sign(lean)`; if already past bail, clamp to 90%
and bail next frame (the "cheese" anti-spam); `cheese = Cheese`. Same rail again in a combo:
`+Same_Grind_Add_Time`; new rail: `-New_Grind_Sub_Time`, cheese cleared. Robot lines
(`GetRobotRailMult() < 0.5`) add time and nudge the lean. `CHEAT_PERFECT_MANUAL`/`_RAIL` zero lean each
frame.

## 6. Vert, lip tricks, transfers

**Launch** `maybe_straight_up` `:2866`: leaving ground with `LAST_POLY_WAS_VERT`: `n = current_normal,
n.y = 0, normalize`; **`vel.RotateToPlane(n)`** (velocity rotated into the vertical plane of the face, length
kept, so you go straight up regardless of the last polygon's pitch); `new_normal(n)` (skater's up = wall
normal); `m_fall_line = forward with y negated`; `pos += n * Physics_Vert_Push_Out`; `VERT_AIR,
TRACKING_VERT, AUTOTURN`; `m_vert_upstep = 6`. From vert `do_jump` uses the `_air_` ranges.

**Tracking** `:4985-5085`: each air frame a horizontal feeler at coping height (30 in each side of the wall)
re-finds the vert face; tries `m_vert_upstep` higher first (halving on miss, binary-searching the lip), then
down to 30 in lower; `pos.xz = found + Physics_Vert_Push_Out`, `new_normal(flat)`,
`vel.RotateToPlane(flat)`. Follows curved/cornered QPs; `change_dot > 0.02` guard at right angles.

**Break vert** `:2927`: Up alone > `Skater_vert_push_time` (no Square/Circle) at take-off, or later while
`CAN_BREAK_VERT` (expires `Skater_Vert_Allow_break_Time`, requires an Up tap within
`Skater_vert_active_up_time`) with nothing under the feet: `speed = |vel| * physics_break_air_speed_scale;
vel.xz += -display_normal.xz * speed; vel.y *= physics_break_air_up_scale;` pitch
`Skater_Break_Vert_forward_tilt`, facing = velocity, VERT flags off.

**Spine/hip** `:3017`, `:3298` (buttons: PS2 `L2 || R2`, Xbox `L2 && R2`, GC `L1 && R1`,
`skater.h:94-109`): while rising, find the take-off face, step 10..500 in in 6 in steps with 4000 in rays for
a `mFD_VERT` face (`|n.y| < 0.707`) with horizontal normal `dot <= 0.95` vs start; `hip = dot > -0.866`;
Left/Right widen 45 deg. Velocity made purely vertical if faces not opposite (`< 0.9`) or gap > 2 ft;
`time = calculate_time_to_reach_height` (>= 0.1); `m_spine_vel = (target - pos)/time` (y 0); > 24 in spines
need enough speed; matrix `SmoothStep` slerp over `max(time, 0.9)` to the landing orientation (entry yaw
deviation > 30 deg preserved). **Acid drop** `:3379`: spine buttons in plain air (not after a collision or
vert air; "skated off edge" = within 250 ms of leaving ground without a jump), scan 0..500 in (3 in steps,
+24 beyond 100) for a facing vert (`dot >= 0.05`), require reachability, air time
>= `Physics_Acid_Drop_Min_Air_Time`, a clear two-segment path (retry 24 in higher), pop
>= `Physics_Acid_Drop_Pop_Speed` (cap 2x). Post-transfer speeds above `1.25 * Skater_Max_Speed_Stat`
persist and decay (`Physics_Transfer_Speed_Limit_Override_Max`, `_Drop_Rate`, `:3776`).

**Lip** `got_rail` `:6882-6960`, `do_lip_physics` `:7233`: a rail snap becomes a lip when `vel.y > 0`,
`|matrix[Y].y| < sin(LipPlayerHorizontalAngle)`, `matrix[Z].y > 0`, last ground `|n.y| < cos(LipRampVertAngle)`,
`|matrix[X].y| < sin(LipAllowAngle)` (`LipAllowAngle_Override` on `LIP_OVERRIDE` nodes; `AllowLipNoGrind`
forces). Velocity zeroed, `m_pre_lip_pos = pos`, `SetState(LIP)`, `pos = rail_pos`, up = horizontal ramp
normal, forward = world up; `LipTrick` script -> `DoBalanceTrick Type=Lip`. Exit hops via
`HandleLipOllieDirection` `:445` (`Lip_side_hop_speed`, `Lip_side_jump_speed` after
`Lip_held_jump_out_time`, `Lip_along_jump_speed` after `Lip_held_jump_along_time`). Leaving LIP restores
`m_pre_lip_pos` (`:1323`) so you drop back in from where you really were.

## 7. Walls (brief)

**Bonk** `bounce_off_wall` `:2420`: `rotate_away_from_wall` turns velocity+facing by
`angle * Wall_Bounce_Angle_Multiplier`; beyond `Wall_Bounce_Dont_Slow_Angle`, speed
`*= 1 - (|angle| - min)/(90deg - min)` (head-on = stop); above `Wall_Bounce_Dont_Flail_Speed` a
`FlailLeft/Right` anim; placed 6 in off; corner escape = 180 deg turn at half speed. Air bonk `:5813`:
`vel.y` kept, XZ projected onto the wall + 10% push-out.

**Wall push** `:4179`: Triangle on a near-head-on ground bonk: reflect velocity, lose
`Physics_Wallpush_Speed_Loss` (floor `Physics_Wallpush_Min_Exit_Speed`), cooldown
`Physics_Disallow_Rewallpush_Duration`.

**Wall plant** `:4245`: air, wall >= `Physics_Wallplant_Min_Approach_Angle` head-on, height
>= `Physics_Min_Wallplant_Height`, `Wallplant_Trick` input: horizontal reflected and damped (`_Speed_Loss`,
floor `_Min_Exit_Speed`), `vel.y = Physics_Wallplant_Vertical_Exit_Speed`,
`Physics_Wallplant_Distance_From_Wall` off, frozen for `Physics_Wallplant_Duration` ms then AIR. Refused if
the wall ends within 0.15 s of rise.

**Wall ride** `:4418`, `:6223`: `mFD_WALL_RIDABLE`, Triangle held or within `Wall_Ride_Triangle_Window` s,
`Wall_Ride_Delay` since last, along-wall speed >= `Wall_Ride_Min_Speed`, incidence
< `Wall_Ride_Max_Incident_Angle`, tilt < `Wall_Ride_Max_Tilt`, `Wall_Ride_Upside_Down_Angle`. Entry
`pos = hit + normal`, `vel.RotateToPlane(normal)`, up = wall normal. Per frame: gravity `Wall_Ride_Gravity`,
velocity/facing rotated about the wall normal by `Wall_Ride_Turn_Speed` rad **per frame** toward down (stop
at `dot > 0.68`); forward feeler (curves followed; `normal.y > 0.9` lands, rail tried first); ceiling feeler
18 in off; down feeler `Wall_Ride_Down_Collision_Check_Length`; losing the wall pushes 18 in out into AIR
(+`normal*100` on non-wallable). Ollie: `vel += Wall_Ride_Jump_Out_Speed * normal;
vel.y += Wall_Ride_Jump_Up_Speed`.

## 8. Camera (`Gel/Components/SkaterCameraComponent.cpp`; `skatercam.cpp` is the old copy, not instantiated)

Per-mode params from `Skater_Camera_Array` (physics.q; modes NEAR/MEDIUM(default)/FAR/MEDIUM_LTG + replay):
`horiz_fov, behind, above` (feet), `tilt` (rad), `origin_offset, lip_trick_tilt, lip_trick_above, slerp,
vert_air_slerp, vert_air_landed_slerp, lerp_xz, lerp_y, vert_air_lerp_xz, vert_air_lerp_y, grind_lerp,
zoom_lerp, grind_zoom, big_air_trick_zoom, lip_trick_zoom`. Constructor fallbacks (`:88-95`): `zoom_lerp
0.0625, lerp_xz 0.25, lerp_y 0.5, vert_air_lerp_xz 1.0, vert_air_lerp_y 1.0, grind_lerp 0.1`. Hard constants:
tilt addition +/-20 deg (`TILT_MAX 0.34907`), +40 deg/s in air, restore 160 deg/s; `VERT_AIR_LANDED_TIME
10/60 s`; `PERFECT_ABOVE 3 in`; `CAMERA_SLERP_STOP 0.9999`; grind lean `pi/6 per 4096`; mode changes
interpolate behind/above over `time` s in 1/60 steps. **All lerps are per-60-Hz-frame fractions**, corrected
by `GetTimeAdjustedSlerp(L, dt) = t*L/(1 - L + t*L)`, `t = dt*60` (constant lag distance at any frame rate).

Per frame `:281-935`: (1) target = skater display matrix (pre-wall matrix during WALL); if moving
(`|vel.xz| > 0.1`), vert cam, or transfer: forward = velocity flattened by `0.8 * dot(vel, ground_normal)` on
ground (20% slope pitch kept), fully flat vs world up in air, 0.7 descending a spine; else facing. **Vert cam**
(`UseVertCam`: LIP, or VERT_AIR with `CAN_BREAK_VERT` expired and no transfer, or straight-up lip exit):
forward = `(0,-1,0)`, overhead. Acid drop uses `m_acid_drop_camera_matrix`. (2) look-around yaw, pitch
`tilt + tilt_addition` (LIP: `lip_trick_tilt`; none in vert cam); LIP yaws 90 deg to the clearer side (72 in
feelers), decided once. (3) orientation slerp with `slerp` / `vert_air_slerp` / `vert_air_landed_slerp` (10
frames after vert landing); per-frame angular limiter (`this_dot < mLastDot*0.9998` -> scale slerp down)
kills whip-pans at rail corners; skipped once within `CAMERA_SLERP_STOP`. (4) tripod lags position with
separate `lerp_xz`, `lerp_y` (vert variants); `SNAPPED_OVER_CURB` -> `lerp_y = 1` that frame;
`SNAPPED`/teleport -> instant (3 frames). (5) zoom target `big_air_trick_zoom` (latched while tricking in
vert air), `grind_zoom` on RAIL, `lip_trick_zoom` on LIP; `cur += (target - cur) * zoom_lerp`;
`behind = mBehind * zoom`, `above -> 3 in` as zoom -> 0; right-stick look-up shortens behind to 40%.
(6) `cam = tripod + frame.z*behind + skater_up*above`, re-aimed at the **true** skater position +
`skater_up*above` (lag shows as distance, "feeling of speed"); grind lean rolls the view. (7) collision: ray
focus -> cam+2 in, min 11.9 in, 8 in side feelers.

## 9. Frame rate, units, input

- `Tmr::FrameLength()` (`Sys/ngps/p_timer.cpp:441`) = `render_length / FPS * slomo`, `render_length` = mean
  of last 4 vblank deltas (`vSMOOTH_N = 4`) each clamped to [1,4] (values > 10 or <= 1 become 1). So `dt` is
  in [1/60, 4/60] s NTSC. Variable step, but every per-frame constant is written `x * 60 * dt` or rate `* dt`;
  `FrameRatio() = dt*60` "regardless of NTSC/PAL". Not time-scaled: rail display lerp 0.3,
  `Wall_Ride_Turn_Speed`, camera zoom lerp, camera mode interpolators. **Port advice: 60 Hz
  `_physics_process`, treat every "per frame" constant as per 1/60 s.**
- Units: inches, seconds, radians for rates, degrees for physics.q angles passed through `DegToRad`,
  milliseconds for holds. 1 m = 39.37 in; ~1100 in/s max is ~28 m/s.
- Input: the skater reads **digital** Up/Down/Left/Right. Left stick centred at 128, dead zone
  `vANALOGUE_TOL = 50` (`inpman.h:70`, ~39% travel); past it the direction counts as pressed
  (`OverrideAnalogPadWithStick`, `inpserv.cpp:518`) unless the D-pad is held. **No proportional steering
  anywhere.** `CSkaterButton` stamps press/release times; `GetPressedTime()` (ms held) drives every ramp.
  Buttons: X ollie (hold to charge), Square flip/kick, Circle grab, Triangle grind/lip/wallride, L1/R1 spin,
  L2/R2 transfer/acid drop/recovery, Down brake + sharp turn, Up break vert / sticky crests / skitch
  (> `Skitch_Hold_Time`).

## 9b. The score (`Code/Sk/Modules/Skate/score.cpp`, the trick scripts)

**Points** are in the trick scripts (`Score = ` in `airtricks.q`, `grindscripts.q`, `manualtricks.q`,
`liptricks.q`; `SetTrickScore` in `walltricks.q`, `groundtricks.q`, `tricks.q`): Kickflip, Heelflip, Pop Shove-It,
Impossible 100, Hardflip 300; Melon, Indy, Nosegrab, Tailgrab 300, Stalefish 350; 50-50, Nosegrind, 5-0 100,
Boardslide, Lipslide 200; Manual, Nose Manual 100; Nose Stall 300, Axle Stall 400, Rock to Fakie, Blunt to Fakie
500, Disaster 600; BS/FS Wallride 200, Wallplant 750 (`Air_Wallplant`), `TRANSFER_POINTS` 250 (spine and hip),
`ACID_DROP_POINTS` 250, Revert 100, Ollie 75. The created skater's specials (`skater_profile.q`): McTwist 5000
(`SpAir_R_D_Circle`), Kickflip Underflip 1000 (`SpAir_L_R_Square`), Tailblock Slide 500 (`SpGrind_R_D_Triangle`),
triggered by `TripleInOrder` (two directions then the button within 400 ms) only in the special state.

**A trick's worth** `:170-200`: `base * deprecMult(uses) * spinMult(index) / 200`, with `DEPREC_VALUES`
`{100, 75, 50, 25, 10}` per cent indexed by how often the trick was done in the run (banked combos plus this one,
`:642-660`; a bail clears the combo's counts, `:1196`) and `SPIN_MULT_VALUES` `{2, 3, 4, 5, 6, 7}` over 2 indexed by
`(spin + spin_count_slop) / 180` (`:755-850`), capped at the last. The spin attaches to the current spin trick (the
first non-blocking trick after the last blocking one), or to the Ollie, whose odd half turns swap FS and BS. No
points accrue for time on a grind or a manual.

**Special** `:295-305`, `:1010-1035`, `:1405-1427`: `m_specialScore` 0..3000; with `NewSpecial` (physics.q, on)
it is fed `scorePot * mult - m_recentSpecialScorePot` every time the combo grows; drains `50/s`, `200/s` while
active; `>= 3000` sets active, active until it reaches 0; `Bail()` zeroes it. `CSkater::GetStat` `:588` adds 3 to
every stat while active, and `CTrickComponent` `:2152` checks the special tricks array only then.

## 9c. Walking (`Code/Gel/Components/WalkComponent.cpp`, `walking_control.q`, `switch_control.q`)

Getting off and on is `SwitchControl_Trigger` (`PressTwoAnyOrder L1 R1 400`; Xbox Black, GC Z), queued as
`SkateToWalkTricks` on the ground and in the air. On foot the skater carries the board (`IsBoardMissing` is only
for levels that take it away). Back onto the board from the air is the normal landing; `maybe_in_air_acid_drop`
`:2455` and `maybe_jump_to_acid_drop` `:2480` take the spine buttons (`WALK_SPINE_BUTTONS`) in the air or on the
ground, the latter jumping with `acid_drop_jump_velocity` (400 in/s) first, both through the skater's own
`maybe_acid_drop` with the walking flag (a 100 in scan on the ground, 200 in of scan height, `SkateInAble_*`
offsets for rails and lips). Walk speeds: `max_slow_walk_speed` 120, `max_fast_walk_speed` 250,
`max_slow_run_speed` 500 in/s; `vert_wall_jump_speed` 600.

## 9d. Skitching (`maybe_skitch` `:4738`, `start_skitch` `:8244`, `move_to_skitch_point` `:2211`, `StopSkitch` `:8344`)

`SKITCH_BUTTON` (`skater.h:119`) is Up held longer than `Skitch_Hold_Time` (200 ms); on the ground the nearest
skitch point of any `CSkitchComponent` within `Skitch_Max_Distance` (120 in) is taken. While skitching the
velocity is the contact's `* skitch_speed_match` (1.0) and the skater is moved to the skitch point
(`skitch_suck_speed` 200 in/s); L1/R1/L2/R2 step between a car's points. Balance is `SkitchParams`
(`Lean_Gravity` 0.01, `Instable_Base` 0.5, `Instable_Rate` 0.04, `Lean_Min_Speed` 5, `Lean_Rnd_Speed` 10,
`Lean_Acc` 8, bail 4000) on Right/Left, `Tweak 5`; the `Skitch` script scores "Skitchin" 500 and `Display
Blockspin`. Down held, the meter's end (`OffMeterTop/Bottom`) and an ollie all run `SkitchOut`: `StopSkitch`,
`LandSkaterTricks`, back to `OnGroundAI`, no bail.

## 9e. The trick list (`protricks.q`, `airtricks.q`, `grindlist.q`, `grindscripts.q`, `liptricks.q`)

A skater's mapping is a structure of slots (`Air_SquareL`... `Air_SquareDR`, `Air_CircleL`..., `Air_U_U_Square`,
`Air_D_D_Square`, a lip set, `JumpSlot`, `ExtraSlot1/2`); the created skater's is `CustomTricks_default` (with
`HawkLip`): Square L Kickflip 100, R Heelflip 100, U Impossible 100, D Pop Shove-It 100, UL Hardflip 300, UR
Inward Heelflip 350, DL Varial Kickflip 300, DR Varial Heelflip 300, U,U Sal Flip 900, D,D Ollie North 169;
Circle L Melon 300, R Indy 300, U Nosegrab 300, D Tailgrab 300, UL Japan 350, UR Madonna 750, DL Benihana 300,
DR Airwalk 450; lips (HawkLip) L Varial Invert to Fakie 450, R BS Boneless 550, U FS Noseblunt 550, D Invert 500,
UL Andrecht Invert 550, UR The Switcheroo 600, DL Gymnast Plant 575, DR One Foot Invert 500, none
`DefaultLipTrick` Nose Stall 300. `GrindTrickList` is nine sub-arrays by direction (none, U, D, L, R, UL, UR, DL,
DR), each indexed by the approach flags (right, parallel, backwards, regular): none 50-50 100 / Boardslide 200 /
Lipslide 200, U Nosegrind 100, D 5-0 100, L Tailslide 150 (Boardslide across), R Noseslide 150 (Lipslide
across), UL Overcrook 125, UR Crooked 125, DL Smith 125, DR Feeble 125; `GrindTricks` U,U Nosebluntslide 250,
D,D Bluntslide 250. `ExtraTricks` (`Trigger Press Square 300`, `IsExtra`, `UseCurrent`) chain: Kickflip -> Double
500 -> Triple 1000, Heelflip likewise, Pop Shove-It -> 360 500 -> 540 1000, Impossible -> Double 500 -> Triple
1000, Hardflip -> 360 Hardflip 500, Varial Kickflip -> 360 Flip 550, Varial Heelflip -> 360 Heelflip 500, Inward
Heelflip -> 360 Inward Heelflip 500, Sal Flip -> 360 Sal Flip 1150, Ollie North -> Back Foot Flip 1050; Melon ->
Method 400, Indy -> Stiffy 500, Nosegrab -> Rocket Air 400, Tailgrab -> One Foot Tailgrab 500, Japan -> One Foot
Japan 800, Madonna -> Judo 1150, Benihana -> Sacktap 1500, Airwalk -> Christ Air 550.

## 10. What a rewrite must copy, ranked

1. **Velocity is rotated, never projected, through ground transitions**: `RotateToPlane` at the top of every
   ground frame, the `move_again` re-application when a curve cuts the move short, and rotation into the
   vertical plane / rail / wall on entry. Speed leaves only via friction, brakes, and the landing projection
   (`:1516`, `:1666`, `:2890`).
2. **The board never slides**: `remove_sideways_velocity` snaps velocity to +/- facing at full speed; turning
   rotates velocity and facing together at constant `Physics_Ground_Rotation` (`_Sharp_` with Down),
   speed-independent (`:3911`, `:4005`).
3. **Vert is a vertical plane you keep riding in the air**: up = wall normal, `TRACKING_VERT` re-finds the
   coping each frame, `AUTOTURN` back down `m_fall_line`, gravity `/ Physics_vert_hang_Stat`, Up breaks the
   plane (`:2866`, `:4985`, `:5480`, `:2927`).
4. **Ollie height linear in X hold**: `lerp(min, max, min(tense_ms, skater_max_tense_time)/skater_max_tense_time)`,
   downward velocity discarded first, separate vert/boneless ranges (`:8098-8170`).
5. **Grinds**: sweep the movement segment vs rail segments with 8x parallel bias inside `Rail_Max_Snap`,
   air-only with Triangle; lock on with rotated velocity + `Rail_Speed_Boost`; rail gravity; automatic
   corners/joins up to `Rail_Corner_Leave_Angle` (`rail.cpp:994`, `:7040`, `do_rail_physics`,
   `skate_off_rail`).
6. **One balance model** for manual/grind/lip: `lean += (lean*G + dir) * (base + t*rate) * 60dt`, `Lean_Acc`
   on buttons, random jitter, bail at `Lean_Bail_Angle`, carried needle velocity and "cheese"; manuals do
   not slow you (`manual.cpp`).
7. **Landing never fails in physics**: project velocity onto the plane, snap matrix to the normal;
   bails/sloppy/spin rounding (`spin_count_slop`, 180 flat / 360 vert) are script decisions. Air control =
   yaw at `Physics_air_rotation_stat` with tap dead time and ramp, Up/Down pitch, auto-righting (`:5182`,
   `:5370`, `:5755`).
8. **Snap-up over curbs and thin walls** (`Physics_Air_Snap_Up`, `SNAP_OVER_THIN_WALLS`) plus the ground
   snap rules (`Ground_stick_angle`, `Physics_Ground_Snap_Down`, drop bound `|move| * tan(angle)`)
   (`:6022`, `:2524`).
9. **Speed model**: continuous kick up to a cap (no impulse), quadratic wind drag lower when crouched, soft
   cap + heavy drag and a hard cap, slope gravity, and no friction with autokick off (`:1416`, `:1884-1997`).
10. **Camera**: forward from velocity flattened 80% against the ground, lagged XZ/Y tripod re-aimed at the
    true skater, 20 deg extra air tilt, overhead vert cam, grind/big-air zoom, angular-change limiter
    (`SkaterCameraComponent.cpp:281-935`).

Honourable mentions: display normal lerp (`Normal_Lerp_Speed`) while physics snaps;
`flip_if_skating_backwards`; wallride per-frame turn to down; `SNAPPED` camera hints; Special = +3 to every
stat.

## Appendix A: physics.q symbols read by the skater code (not in the repository)

Ground: `Physics_Ground_Gravity, Physics_Rolling_Friction, Physics_Standing_Air_Friction,
Physics_Crouched_Air_Friction, Physics_Heavy_Air_Friction, Physics_Brake_Acceleration,
Physics_Ground_Rotation, Physics_Ground_Sharp_Rotation, Skater_max_sloped_turn_speed,
Skater_max_sloped_turn_cosine, Skater_Slow_Turn_on_slopes, Skater_Flip_Speed, Ground_stick_angle,
Ground_stick_angle_forward, Physics_Ground_Snap_Up, Physics_Ground_Snap_Down, Normal_Lerp_Speed,
Wall_Non_Skatable_Angle, Skater_First_Forward_Collision_Height/_Length, Skater_side_collide_height/_length,
Skater_air_extra_side_col, Skater_Min_Distance_To_Wall, Skate_min_wall_lean_push_speed,
Skate_wall_lean_push_time/_length/_height, Physics_Time_Before_Free_Revert`.

Stats: `Skater_Max_Speed_Stat, Skater_Max_Max_Speed_Stat, Skater_Max_Standing_Kick_Speed_Stat,
Skater_Max_Crouched_Kick_Speed_Stat, Physics_Standing_Acceleration_stat,
Physics_crouching_Acceleration_stat, Skater_Default_Stats`.

Air/jump: `Physics_Air_Gravity, Physics_Air_hang_Stat, Physics_vert_hang_Stat, moon_gravity,
skater_max_tense_time, Physics_[Boneless_][air_]Jump_Speed_[min_]stat, Physics_air_rotation_stat,
Physics_air_tap_turn_speed_stat, Physics_Air_No_Rotate_Time, Physics_Air_Ramp_Rotate_Time,
skater_autoturn_cancel_time, skater_autoturn_vert_angle, Skater_autoturn_speed, Physics_air_lean_stat,
Physics_Air_No_Lean_Time, Physics_Air_Ramp_Lean_Time, skater_upright_sideways_speed,
Physics_recover_rate_stat, Physics_Air_Snap_Up, Skater_default_head_height, spin_count_slop`.

Vert/transfer: `Physics_Vert_Push_Out, Skater_vert_push_time, Skater_vert_active_up_time,
Skater_Vert_Allow_break_Time, physics_break_air_speed_scale, physics_break_air_up_scale,
Skater_Break_Vert_forward_tilt, Physics_Acid_Drop_Pop_Speed, Physics_Acid_Drop_Min_Air_Time,
Physics_Acid_Drop_Min_Land_Speed, Physics_Acid_Drop_Walking_On_Ground_Search_Distance,
Physics_Transfer_Speed_Limit_Override_Max/_Drop_Rate, Carplant_upward_boost, Carplant_forward_boost`.

Rails/lip: `Rail_Max_Snap, Rail_Speed_Boost, Point_Rail_Speed_Boost, Physics_Point_Rail_Kick_Upward_Angle,
Physics_Rail_Gravity, Rail_Corner_Leave_Angle, Rail_Tolerance, Rail_Bad_Ledge_Drop_Down_Dist,
Rail_Bad_Ledge_Side_Dist, Rail_Minimum_Rerail_Time, Rail_jump_rerail_time, Rail_walk_rerail_time,
Rail_Jump_Angle, GrindTrickList, LipAllowAngle[_Override], LipPlayerHorizontalAngle, LipRampVertAngle,
Lip_side_hop_speed, Lip_side_jump_speed, Lip_along_jump_speed, Lip_held_jump_out_time,
Lip_held_jump_along_time, SkateInAble_*`.

Balance: per `ManualParams/GrindParams/LipParams/SkitchParams` as listed in section 5; globals
`BalanceSafeButtonPeriod, BalanceIgnoreButtonPeriod, robot_rail_add_time, robot_rail_nudge,
DefaultWobbleParams`.

Walls: `Wall_Bounce_Dont_Slow_Angle, Wall_Bounce_Dont_Flail_Speed, Wall_Bounce_Angle_Multiplier,
Physics_Disallow_Rewallpush_Duration, Physics_Wallpush_Min_Exit_Speed, Physics_Wallpush_Speed_Loss,
Physics_Disallow_Rewallplant_Duration, Physics_Min_Wallplant_Height, Physics_Wallplant_Min_Approach_Angle,
Wallplant_Trick, Physics_Wallplant_Min_Exit_Speed, Physics_Wallplant_Speed_Loss,
Physics_Wallplant_Vertical_Exit_Speed, Physics_Wallplant_Distance_From_Wall, Physics_Wallplant_Duration,
Physics_Wallplant_Disallow_Grind_Duration, Physics_Ignore_Ceilings_After_Wallplant_Duration,
Wall_Ride_Triangle_Window, Wall_Ride_Delay, Wall_Ride_Min_Speed, Wall_Ride_Upside_Down_Angle,
Wall_Ride_Max_Incident_Angle, Wall_Ride_Max_Tilt, Wall_Ride_Gravity, Wall_Ride_Turn_Speed,
Wall_Ride_Down_Collision_Check_Length, Wall_Ride_Jump_Out_Speed, Wall_Ride_Jump_Up_Speed`.

Camera: `Skater_Camera_Array` (+`_2P_Vert_`, `_2P_Horiz_`), `Skater_Cam_Horiz_FOV`. Misc:
`Skitch_Hold_Time, Skitch_Max_Distance, skitch_speed_match, BashPeriod, BashSpeedupFactor,
BashMaxPercentSpeedup`.

## Appendix B: hard-coded numbers worth keeping

| Value | Meaning | Where |
|---|---|---|
| 50 in/s | "slow": brake threshold rules | `:1795,1804` |
| 10 in/s | sharp-turn ramp applies below; `ZeroIfShorterThan(10)` after landing | `:3929`, `:5251` |
| 600 ms | `STOPPED_TURN_RAMP_TIME` | `skater.h:175` |
| 0.1 in | `move_again` shortfall tolerance | `:1688` |
| 200 in | ground snap ray below feet | `:2545` |
| 0.25 | side hit is a wall if `abs(dot(n, up))` below | `:4142` |
| 0.01 | forward face is a wall not a QP if `abs(dot)` below | `:2395` |
| 6 in | bonk push-off; rail collision tolerance | `:2489`, `:6950` |
| 0.5 | min `normal.y` for air snap-up target | `:6064` |
| 0.15 s | "about to reach top of wall" look-ahead | `:4280`, `:4449` |
| 4000 in | vert/transfer search rays | `:3068` |
| 10..500 in, step 6 | transfer target search | `:3341` |
| 24 in | spine width limit for drift | `:3130` |
| 0.9 s | min transfer slerp duration | `:3256` |
| 30 deg | hip-transfer yaw deviation ignored | `:3242` |
| 0.3 | rail display forward lerp per frame | `:7605` |
| 0.122 | parallel-rail weight in `StickToRail` | `rail.cpp:1074` |
| 18 in | push-out when a wallride ends | `:6396` |
| 100 in/s | boost off a non-wallable face during wallride | `:6459` |
| 4 in | half rail width for `Side()` | `rail.cpp:605` |
| 3 in / 0.9999 / 11.9+2 in | camera perfect-above / slerp stop / min distance | `CameraUtil.h`, `.cpp` |
| 1/60..4/60 s | `FrameLength` range | `p_timer.cpp:355-367` |
| 50/128 | stick dead zone before it becomes a d-pad press | `inpman.h:70` |

Key finding for the port: **the C++ contains no landing tolerance, no push impulse, no manual speed penalty,
and no terminal velocity**; those "feel" behaviours the community attributes to THPS are the
rotate-not-project velocity handling, the digital-input ramps on hold time, the rail scoring bias, and
script-side decisions on top of a physics layer that never refuses a landing. The full `physics.q` numbers
would have to come from a game data dump; every symbol above is the exact key to look up there.
