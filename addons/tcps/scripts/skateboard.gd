class_name Skateboard
extends Node3D
## Tim Cope's Pro Skater: a skateboard the Player picks up with "action" and rides through the Player's
## [Riding] state. The board owns the movement, the sounds and its own [SkateboardCamera]; the Player only
## lends its body, its input and its animations (requested through the rideable signals), and its Riding state
## makes [member camera] current and turns the Player's step-up ray off while the board owns the ground.
##
## The physics is Neversoft's THUG skater (Code/Sk/Components/SkaterCorePhysicsComponent.cpp in the Tony Hawk's
## Underground source), state by state. On the ground the velocity is rotated into the surface every tick with its
## speed kept, gravity along the surface slows a climb, turning rotates the velocity with the facing at a constant
## rate so the board never slides, a kick is a steady acceleration up to a cap, and a wall is bounced off with a
## speed loss that grows with the angle. The ollie is charged: its height is linear in how long the button was held.
## Leaving a wall steeper than [constant VERT_ANGLE] is a vert launch, held in the wall's plane through the air.
## In the air with Grind held the board looks for a [Rail] each tick, snaps to the nearest one it is travelling
## along, and rides it under a [SkateBalance]; the same balance runs a manual on the ground. Flip and grab tricks
## in the air, the spin counted on landing, reverts, grinds and manuals all go into a [SkateTricks] combo, banked
## on a clean landing and lost in a bail, and shown on the board's HUD.
##
## Over the network the board is one node in the world on every peer, and its BodySynchronizer carries its position,
## rotation and [member rider_peer]. Getting on asks the server to put the board under the rider's model on every
## peer and then hand it to the rider's peer, in that order, so the rider's copy starts sending its place only once
## everybody has it under their feet; getting off does the same back to the parent it stood under and to the server.
## A rider who drops out is handed back by every peer on its own.

signal locomotion_requested(state_path: String, immediate: bool) ## Asks the rider to play an animation node.
signal locomotion_blend_requested(path: String, value: float) ## Asks the rider to set an animation blend value.
signal jump_requested ## Asks the rider to run its jump animation (the pop itself is applied here).
signal trick_started(kind: String) ## A manual or a grind began ("manual", "nose_manual", "grind").
signal trick_ended(kind: String, bailed: bool) ## It ended, and whether the needle went off the meter.
signal combo_banked(points: int) ## A clean landing put the combo into the score.
signal combo_lost ## A bail threw the combo away.

enum State { GROUND, AIR, RAIL }

@export_category("Skateboarding Controls")
@export_group("Keyboard/Mouse Actions")
@export var keyboard_dismount_action: StringName = &"whistle"
@export var keyboard_jump_action: StringName = &"jump"
@export var keyboard_grind_action: StringName = &"action"
@export var keyboard_flip_action: StringName = &"attack"
@export var keyboard_grab_action: StringName = &"sprint" ## On the ground the same button is the crouched push.
@export var keyboard_revert_actions: Array[StringName] = [&"focus", &"shoot"] ## THUG's L2 and R2 on a vert landing.
@export var keyboard_sprint_action: StringName = &"sprint"
@export var keyboard_kick_push_action: StringName = &"move_up"

@export_group("Controller/Touch Actions")
@export var pad_dismount_action: StringName = &"whistle"
@export var pad_jump_action: StringName = &"jump"
@export var pad_grind_action: StringName = &"action"
@export var pad_flip_action: StringName = &"attack"
@export var pad_grab_action: StringName = &"sprint"
@export var pad_revert_actions: Array[StringName] = [&"focus", &"shoot"]
@export var pad_sprint_action: StringName = &"sprint"
@export var pad_kick_push_action: StringName = &"move_up"

const LOCOMOTION: String = "SkateboardingLocomotion" ## The rider's rolling animation node.
const KICK_PUSH: String = "SkateboardingKickPush" ## The rider's push-off animation node.
const LOCOMOTION_BLEND_PATH: String = "parameters/LocomotionStateMachine/SkateboardingLocomotion/blend_position"

# THUG's own numbers from physics.q (the decompiled THUG scripts at atljp/thps-modding-resources), converted from
# inches and milliseconds to metres and seconds, at the middle of each stat range (5 of 10; Special adds 3). The
# THUG symbol is beside each. Gravity is THUG's, not the project's: 3.5 g in the air is what makes a pop snappy.
const INCH: float = 0.0254
const DEAD_ZONE: float = 0.39 ## THUG reads the stick as a d-pad past 50 of 128; nothing is proportional.
const KICK_ACCELERATION: float = 664.5 * INCH ## Physics_Standing_Acceleration_Stat 629..700: a kick is this much every second it is held.
const KICK_MAX_SPEED: float = 445.0 * INCH ## Skater_Max_Standing_Kick_Speed_Stat 394..496: kicking does nothing past this.
const CROUCH_KICK_ACCELERATION: float = 1128.5 * INCH ## Physics_Crouching_Acceleration_stat 1057..1200: holding sprint is THUG's crouched kick.
const CROUCH_KICK_MAX_SPEED: float = 603.5 * INCH ## Skater_Max_Crouched_Kick_Speed_Stat 532..675.
const MAX_SPEED: float = 828.5 * INCH ## Skater_Max_Speed_Stat 757..900: above this the heavy drag applies.
const MAX_MAX_SPEED: float = 1028.5 * INCH ## Skater_Max_Max_Speed_Stat 957..1100: never faster.
const WIND_DRAG: float = 0.00001 * 60.0 / INCH ## Physics_Standing_Air_Friction: THUG takes f * 60 * v^2 in/s^2 off each second; there is no rolling friction to speak of.
const CROUCH_WIND_DRAG: float = 0.000002 * 60.0 / INCH ## Physics_Crouched_Air_Friction: a fifth of it crouched.
const HEAVY_DRAG: float = 0.0001 * 60.0 / INCH ## Physics_Heavy_Air_Friction: the drag above [constant MAX_SPEED].
const BRAKE: float = 900.0 * INCH ## Physics_Brake_Acceleration.
const TURN_RATE: float = 1.8 ## Physics_Ground_Rotation: radians per second, whatever the speed.
const SHARP_TURN_RATE: float = 3.6 ## Physics_Ground_Sharp_Rotation: with Down held.
const STOPPED_TURN_RAMP_TIME: float = 0.6 ## STOPPED_TURN_RAMP_TIME: the turn ramps in over this while nearly stopped.
const STOPPED_SPEED: float = 10.0 * INCH ## Below THUG's 10 in/s the turn ramps.
const SLOW_SPEED: float = 50.0 * INCH ## THUG's 50 in/s: below it a brake stops you.
const FLIP_SPEED: float = 1.0 * INCH ## Skater_Flip_Speed: rolling backwards faster than this turns the skater round.
const WALL_BOUNCE_DONT_SLOW_ANGLE: float = deg_to_rad(30.0) ## Wall_Bounce_Dont_Slow_Angle: a glance shallower than this keeps its speed.
const OLLIE_MIN_SPEED: float = 350.0 * INCH ## Physics_Jump_Speed_min_Stat: a tap.
const OLLIE_MAX_SPEED: float = 432.0 * INCH ## Physics_Jump_Speed_Stat 414..450: a full hold.
const VERT_OLLIE_MIN_SPEED: float = 100.0 * INCH ## Physics_Air_Jump_Speed_min_Stat: the pop off a vert wall is smaller.
const VERT_OLLIE_MAX_SPEED: float = 275.0 * INCH ## Physics_Air_Jump_Speed_Stat.
const MAX_TENSE_TIME: float = 0.2 ## Skater_max_tense_time: holding longer adds nothing.
const OLLIE_GRACE: float = 0.15 ## Seconds after a pop during which the floor is ignored, so a curving wall cannot catch the board and bleed the pop.
const GROUND_GRAVITY: float = 1000.0 * INCH ## Physics_Ground_Gravity, along the surface.
const AIR_GRAVITY: float = 1350.0 * INCH ## Physics_Air_Gravity: 3.5 g.
const RAIL_GRAVITY: float = 2000.0 * INCH ## Physics_Rail_Gravity, along the rail.
const AIR_HANG: float = 1.0 ## Physics_Air_hang_Stat: air gravity is divided by it.
const VERT_HANG: float = 1.1 ## Physics_Vert_hang_Stat: a touch floatier in vert air.
const AIR_SPIN_SPEED: float = 7.3 ## Physics_Air_Rotation_stat 6.85..7.75: radians per second with Left or Right held in the air.
const AIR_NO_ROTATE_TIME: float = 0.1 ## Physics_Air_No_Rotate_Time: a tap does not spin.
const AIR_RAMP_ROTATE_TIME: float = 0.15 ## Physics_Air_No_Rotate_Time plus Physics_Air_Ramp_Rotate_Time: the spin reaches full rate at this hold.
const RAIL_MAX_SNAP: float = 40.0 * INCH ## Rail_Max_Snap: how far a rail can be from the board's path and still take it.
const RAIL_PARALLEL_WEIGHT: float = 0.122 ## rail.cpp:1074: a rail you travel along scores eight times better than one across you.
const RAIL_REGRIND_TIME: float = 0.5 ## Rail_minimum_rerail_time: after riding off the end.
const RAIL_JUMP_REGRIND_TIME: float = 0.3 ## Rail_jump_rerail_time: after an ollie off.
const RAIL_HOP: float = 1.0 * INCH ## THUG lifts the skater an inch leaving a rail so the rail does not catch them again.
const MANUAL_TAP_WINDOW: float = 0.25 ## The two taps of a manual (Up then Down, or Down then Up) within this.
const MANUAL_MIN_SPEED: float = 1.0 ## A manual slower than this falls over.
const BAIL_TIME: float = 0.8 ## Seconds the rider is a passenger after a bail.
const BAIL_SPEED_SCALE: float = 0.25 ## What a bail leaves of the speed.
const REVERT_WINDOW: float = 0.3 ## Seconds after a vert landing in which a revert button keeps the combo.
const BANK_GRACE: float = 0.25 ## Seconds after a landing in which a manual, a grind or a revert carries the combo on before it is banked.
const RAMP_FLOOR_MAX_ANGLE: float = deg_to_rad(88.0) ## Transitions stay "floor" almost to vertical, so the board rides them instead of hitting a wall.
const RAMP_FLOOR_SNAP_LENGTH: float = 1.0 ## Keeps the board glued to a curving transition at speed.
const VERT_ANGLE: float = deg_to_rad(50.0) ## Leaving a floor steeper than this is a vert launch.
const VERT_TRACK_REACH: float = 1.5 ## Metres behind the skater the wall must still be for vert tracking to hold (THUG's tracking feeler).
const GROUND_STICK_ANGLE: float = deg_to_rad(30.0) ## Ground_stick_angle: a surface that turns away faster than this in one tick is left behind, which is how the lip of a wall becomes an air rather than a deck.
const VERT_PUSH_OUT: float = 3.0 * INCH ## Physics_Vert_Push_Out: the skater is held this far off the wall through vert air, so the body clears the coping on the way down.
const BREAK_VERT_SPEED_SCALE: float = 0.75 ## physics_break_air_speed_scale: holding forward at the lip breaks vert, and this share of the speed goes over the deck.
const BREAK_VERT_UP_SCALE: float = 0.75 ## physics_break_air_up_scale: and the climb is trimmed to this.
const MODEL_TILT_SPEED: float = 12.0 ## How fast the model leans onto a transition.
const AIR_TILT_SPEED: float = 2.5 ## How fast the lean eases back upright over flat air; vert air keeps the wall's lean.
const MANUAL_TILT: float = deg_to_rad(25.0) ## How far the model pitches at the edge of the meter in a manual.
const MIN_AIR_TIME: float = 0.1 ## Shorter hops are contact flicker on a steep transition, not a landing to turn for.
const DISPLAY_NORMAL_SPEED: float = 14.0 ## Per-second rate the display normal drifts to the floor normal, smoothing a ramp's facets (THUG's adjust_normal).
const SERVER_PEER: int = 1

var player: Player ## The rider, or the Player looking at the board.
var rider_peer: int = 0 ## The peer whose Player is on the board, 0 when it is free; replicated, and set on every peer by the hand-off.
var blocks_hands: bool = false ## Riding a board leaves the hands free (rideable contract).
var input_type: int = Controls.InputType.KEYBOARD_MOUSE ## Kept equal to the Player's input device by the Riding state.
var state: State = State.GROUND ## Which of THUG's states the skater is in.
var rail: Rail ## The rail under the board while [member state] is RAIL.
var rail_offset: float = 0.0 ## Metres along [member rail].
var rail_sign: float = 1.0 ## 1 travelling from the rail's start to its end, -1 the other way.
var rail_speed: float = 0.0 ## Metres per second along the rail, always positive; [member rail_sign] says which way.
var balance: SkateBalance ## The meter while a manual or a grind is on; null otherwise.
var trick: String = "" ## "manual", "nose_manual" or "grind" while [member balance] runs.
var tricks: SkateTricks = SkateTricks.new() ## The combo and the score.
var air_trick: String = "" ## The flip or grab in progress in the air, or "".
var _air_trick_kind: String = "" ## "flip" or "grab".
var _air_trick_time: float = 0.0 ## Seconds the air trick has run.
var _spin_tally: float = 0.0 ## Degrees of yaw turned in this air.
var _landed_from_vert_at: float = -1.0 ## When the last vert landing was, for the revert window; -1 when none.
var _bank_timer: float = 0.0 ## Counting down since a landing with a combo waiting to be banked.
var vert_out: Vector3 = Vector3.ZERO ## Horizontal direction over the deck of the wall the skater launched from; ZERO on flat air.
var vert_normal: Vector3 = Vector3.ZERO ## Horizontal normal of that wall, into the pipe; the skater is held in its vertical plane through vert air.
var display_normal: Vector3 = Vector3.UP ## The floor normal smoothed over time, for the lean and the camera, so facet edges do not step them.
var last_floor_normal: Vector3 = Vector3.UP
var _vert_point: Vector3 = Vector3.ZERO
var _was_on_floor: bool = false
var _air_time: float = 0.0
var _ollie_grace: float = 0.0
var _tense_since: float = -1.0 ## When the ollie button went down, in seconds of [method Time.get_ticks_msec]; -1 when it is up.
var _air_spin_hold: float = 0.0 ## Seconds Left or Right has been held in the air.
var _turn_hold: float = 0.0 ## Seconds Left or Right has been held on the ground.
var _rerail_at: float = 0.0 ## Seconds (game time) before which no rail is taken.
var _bail_timer: float = 0.0
var _last_tap: StringName = &""
var _last_tap_at: float = -1.0
var _old_position: Vector3 = Vector3.ZERO ## Where the rider was at the end of the last tick; a rail is searched along the move from it.
var _saved_floor_max_angle: float = 0.0
var _saved_floor_snap_length: float = 0.0
var _saved_floor_stop_on_slope: bool = true
var _saved_floor_block_on_wall: bool = true
var _saved_floor_constant_speed: bool = true
var _saved_pivot_height: float = 0.0
var _sfx_was_on_floor: bool = false
var _sfx_was_jumping: bool = false
var _sfx_was_falling: bool = false

@onready var camera: SkateboardCamera = $SkateboardCamera ## The view while ridden (rideable contract).
@onready var board_pivot: Node3D = $Board ## The mesh hangs off this; the animations turn it.
@onready var animation_player: AnimationPlayer = $AnimationPlayer ## "ollie" and one animation per flip trick, named in snake case.
@onready var action_prompt: ActionPrompt = $ActionPrompt
@onready var ground_ray: RayCast3D = $GroundRay ## What the board rolls on, for the roll sounds.
@onready var area: Area3D = $Area3D
@onready var balance_meter: BalanceMeter = $HUD/BalanceMeter
@onready var trick_line: Label = $HUD/TrickLine ## The combo so far.
@onready var trick_total: Label = $HUD/TrickTotal ## What it is worth.
@onready var score_label: Label = $HUD/Score ## The score banked.
@onready var sfx_roll_on_cobblestone: AudioStreamPlayer3D = $SFX_Roll_on_Cobblestone
@onready var sfx_roll_on_concrete: AudioStreamPlayer3D = $SFX_Roll_on_Concrete
@onready var sfx_roll_on_wood: AudioStreamPlayer3D = $SFX_Roll_on_Wood
@onready var sfx_ollie: AudioStreamPlayer3D = $SFX_Ollie
@onready var sfx_land: AudioStreamPlayer3D = $SFX_Land
@onready var _area_layer: int = area.collision_layer
@onready var _home: Node = get_parent() ## Where the board stood before anyone got on; where getting off puts it back on every peer.


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


## Called by [Camera] while the player looks at the skateboard.
func display_menu(_player: Player) -> void:
	if _player.is_riding:
		return
	player = _player
	action_prompt.show_for(player.controls)


## Called by [Camera] when the player looks away from the skateboard.
func hide_menu() -> void:
	action_prompt.hide()
	if player and not player.is_riding:
		player = null


## Called by [Camera] when the player looks at the skateboard and presses "action".
func equip(_player: Player) -> void:
	_player.mount(self)


## Rideable contract: the Riding state hands the Player over. The board goes under the Player's feet on every peer
## (once the server says so) and its camera takes the view. A board another peer is riding refuses a second
## rider: the Player is put back off once the state has finished getting them on.
func mount(_player: Player) -> void:
	if rider_peer != 0 and rider_peer != _player.get_multiplayer_authority():
		_player.dismount.call_deferred(true)
		return
	player = _player
	action_prompt.hide()
	_hand_to(player.get_multiplayer_authority())
	_saved_floor_max_angle = player.floor_max_angle
	_saved_floor_snap_length = player.floor_snap_length
	_saved_floor_stop_on_slope = player.floor_stop_on_slope
	_saved_floor_block_on_wall = player.floor_block_on_wall
	_saved_floor_constant_speed = player.floor_constant_speed
	_saved_pivot_height = player.model_pitch_pivot_height
	player.floor_max_angle = RAMP_FLOOR_MAX_ANGLE
	player.floor_snap_length = RAMP_FLOOR_SNAP_LENGTH
	player.floor_stop_on_slope = false # a board at rest on a transition rolls back down instead of sticking to it
	player.floor_block_on_wall = false # brushing the vert above the arc must not zero the speed the way a wall does on foot
	player.floor_constant_speed = false # speed is along the surface already; no slope compensation on top
	player.model_pitch_pivot_height = 0.0 # lean from the feet, not the hips
	var vertical_speed: float = minf(player.velocity.dot(player.up_direction), 0.0)
	player.velocity = player.velocity.slide(player.up_direction) + (player.up_direction * vertical_speed)
	_was_on_floor = player.is_on_floor()
	state = State.GROUND if _was_on_floor else State.AIR
	_sfx_was_on_floor = _was_on_floor
	last_floor_normal = player.up_direction
	display_normal = player.get_floor_normal() if player.is_on_floor() else player.up_direction
	_old_position = player.global_position
	vert_out = Vector3.ZERO
	vert_normal = Vector3.ZERO
	_ollie_grace = 0.0
	_tense_since = -1.0
	_bail_timer = 0.0
	_end_trick(false)
	tricks = SkateTricks.new()
	air_trick = ""
	_spin_tally = 0.0
	_landed_from_vert_at = -1.0
	_bank_timer = 0.0
	locomotion_requested.emit(LOCOMOTION, false)
	camera.begin(player, self)


## Rideable contract: the Player gets off. The board is left where they stand, back under the parent it stood
## under, the server has it again and the view returns to them. Only the rider gets off it: a refused Player
## leaving the Riding state must not hand somebody else's board back.
func dismount(_player: Player) -> void:
	if rider_peer != 0 and rider_peer != _player.get_multiplayer_authority():
		return
	stop_all_roll_sounds()
	_end_trick(false)
	rail = null
	state = State.GROUND
	camera.end()
	player.floor_max_angle = _saved_floor_max_angle
	player.floor_snap_length = _saved_floor_snap_length
	player.floor_stop_on_slope = _saved_floor_stop_on_slope
	player.floor_block_on_wall = _saved_floor_block_on_wall
	player.floor_constant_speed = _saved_floor_constant_speed
	player.model_pitch_pivot_height = _saved_pivot_height
	player.model_pitch = 0.0
	var drop: Transform3D = Transform3D(Basis(player.up_direction, player.orientation.basis.get_euler().y), player.global_position)
	_hand_to(0)
	global_transform = drop # kept through the reparent home, whenever the server's word for it lands
	vert_out = Vector3.ZERO
	vert_normal = Vector3.ZERO
	player = null


# --- Network ------------------------------------------------------------------------------------------------------

## Puts the board under [param peer_id]'s rider on every peer and hands it (and so its synchronizer) to that peer,
## or, for 0, back where it stood and to the server. The server does both, in that order, so the rider's copy
## starts sending its place only once every peer has the board under their feet; a client asks the server for it
## and, when giving it back, goes quiet first. Offline there is nobody to ask.
func _hand_to(peer_id: int) -> void:
	var authority: int = peer_id if peer_id != 0 else SERVER_PEER
	if multiplayer.get_peers().is_empty():
		_ride_by(peer_id)
		set_multiplayer_authority(authority)
	elif multiplayer.is_server():
		_ride_by.rpc(peer_id)
		_set_authority.rpc(authority)
	else:
		if peer_id == 0:
			set_multiplayer_authority(SERVER_PEER)
		_grant.rpc_id(SERVER_PEER, peer_id)


## A client's request for the hand-off; the server alone answers it.
@rpc("any_peer", "reliable")
func _grant(peer_id: int) -> void:
	if multiplayer.is_server():
		_hand_to(peer_id)


@rpc("any_peer", "call_local", "reliable")
func _set_authority(peer_id: int) -> void:
	set_multiplayer_authority(peer_id)


## Puts this copy under the feet of [param peer_id]'s Player (the one in this branch of the tree, since a test can
## run two), or back under [member _home] for 0; runs on every peer so the board shows under the rider everywhere.
## The pickup area is off while ridden, so nobody is offered a board that is under somebody's feet.
@rpc("any_peer", "call_local", "reliable")
func _ride_by(peer_id: int) -> void:
	rider_peer = peer_id
	area.collision_layer = _area_layer if peer_id == 0 else 0
	if peer_id == 0:
		reparent(_home if is_instance_valid(_home) else get_tree().root)
		return
	for node: Node in get_tree().get_nodes_in_group("Player"):
		if node is Player and node.get_multiplayer_authority() == peer_id and node.multiplayer == multiplayer:
			reparent((node as Player).player_model, false)
			transform = Transform3D.IDENTITY
			return


## A rider who drops out takes the board with them; every peer puts it back where it stood and hands it to the server.
func _on_peer_disconnected(peer_id: int) -> void:
	if peer_id != 0 and peer_id == rider_peer:
		_ride_by(0)
		set_multiplayer_authority(SERVER_PEER)


# --- Input --------------------------------------------------------------------------------------------------------

## Rideable contract: input events while ridden.
func ride_input(_player: Player, event: InputEvent) -> void:
	if event.is_echo():
		return
	# Dismount
	if event.is_action_pressed(_action(keyboard_dismount_action, pad_dismount_action)):
		player.dismount()
		return
	if _bail_timer > 0.0:
		return

	var is_kick_pushing: bool = player.current_locomotion_node == KICK_PUSH

	# Ollie: charged while the button is down, popped when it comes up (THUG handle_tensing and do_jump)
	var jump: StringName = _action(keyboard_jump_action, pad_jump_action)
	if event.is_action_pressed(jump) and not is_kick_pushing:
		_tense_since = _now()
	elif event.is_action_released(jump) and _tense_since >= 0.0:
		var held: float = _now() - _tense_since
		_tense_since = -1.0
		if can_ollie():
			jump_requested.emit()
			_ollie(held)

	# Flip and grab tricks in the air, named by the direction held (THUG's Square and Circle)
	if state == State.AIR and air_trick == "":
		var direction: String = SkateTricks.direction_of(_digital(player.player_input.motion))
		if event.is_action_pressed(_action(keyboard_flip_action, pad_flip_action)):
			_start_air_trick("flip", SkateTricks.named(SkateTricks.FLIPS, direction))
		elif event.is_action_pressed(_action(keyboard_grab_action, pad_grab_action)):
			_start_air_trick("grab", SkateTricks.named(SkateTricks.GRABS, direction))

	# A revert on a vert landing (THUG's L2 and R2): the combo lives on into a manual
	var reverts: Array[StringName] = keyboard_revert_actions if input_type == Controls.InputType.KEYBOARD_MOUSE else pad_revert_actions
	for revert: StringName in reverts:
		if event.is_action_pressed(revert) and _landed_from_vert_at >= 0.0 and _now() - _landed_from_vert_at <= REVERT_WINDOW:
			_landed_from_vert_at = -1.0
			tricks.add("Revert", SkateTricks.REVERT_POINTS)
			_bank_timer = BANK_GRACE
			_refresh_hud()

	# Kick push from (near) standstill
	if event.is_action_pressed(_action(keyboard_kick_push_action, pad_kick_push_action)) \
	and not is_kick_pushing \
	and state == State.GROUND \
	and player.velocity.slide(player.up_direction).length() <= SLOW_SPEED * 0.1:
		locomotion_requested.emit(KICK_PUSH, false)

	# Manual: Up then Down; nose manual: Down then Up (THUG matches the two taps script side)
	for tap: StringName in [&"move_up", &"move_down"]:
		if event.is_action_pressed(tap):
			_tap(tap)


## Whether a pop is possible right now: on the ground, on a rail, or falling back into a vert wall.
func can_ollie() -> bool:
	if player == null:
		return false
	if state == State.RAIL:
		return true
	if state == State.GROUND or (player.is_on_floor() and _ollie_grace <= 0.0):
		return true
	return vert_normal != Vector3.ZERO and player.velocity.dot(player.up_direction) < 0.0


func _tap(tap: StringName) -> void:
	var now: float = _now()
	if state == State.GROUND and balance == null and _last_tap != &"" and _last_tap != tap and now - _last_tap_at <= MANUAL_TAP_WINDOW \
	and player.velocity.slide(player.up_direction).length() >= MANUAL_MIN_SPEED:
		_start_trick("manual" if _last_tap == &"move_up" else "nose_manual")
		_last_tap = &""
		return
	_last_tap = tap
	_last_tap_at = now


## The stick as THUG reads it: a d-pad, with nothing proportional.
func _digital(motion: Vector2) -> Vector2:
	return Vector2(
		signf(motion.x) if absf(motion.x) > DEAD_ZONE else 0.0,
		signf(motion.y) if absf(motion.y) > DEAD_ZONE else 0.0)


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# --- Physics ------------------------------------------------------------------------------------------------------

## Rideable contract: moves the rider this physics frame, then the sounds and the camera.
func ride(_player: Player, delta: float) -> void:
	var up: Vector3 = player.up_direction
	_ollie_grace = maxf(_ollie_grace - delta, 0.0)
	_bail_timer = maxf(_bail_timer - delta, 0.0)
	var motion: Vector2 = _digital(player.player_input.motion) if _bail_timer <= 0.0 else Vector2.ZERO
	# THUG crouches for the faster push while the ollie button is held; sprint does the same here
	var sprint: bool = (Input.is_action_pressed(_action(keyboard_sprint_action, pad_sprint_action)) or _tense_since >= 0.0) and not player.is_exhausted and motion.y > 0.0
	_tick_tricks(delta)
	var grind_held: bool = Input.is_action_pressed(_action(keyboard_grind_action, pad_grind_action)) and _bail_timer <= 0.0

	if state == State.RAIL:
		_grind(motion, delta)
	else:
		var on_floor: bool = player.is_on_floor() and _ollie_grace <= 0.0
		var normal: Vector3 = player.get_floor_normal() if on_floor else up
		if on_floor and state == State.GROUND and normal.angle_to(last_floor_normal) > GROUND_STICK_ANGLE and last_floor_normal.angle_to(up) > VERT_ANGLE:
			# The wall turned into the deck under the board faster than a board can follow (THUG's snap_to_ground and
			# Ground_stick_angle): the board has left the wall, and the floor is ignored for a moment so the coping
			# cannot catch it on the way up
			on_floor = false
			normal = up
			_ollie_grace = OLLIE_GRACE
		if on_floor:
			if not _was_on_floor:
				_land(normal)
			state = State.GROUND
			last_floor_normal = normal
			_air_time = 0.0
		else:
			if _was_on_floor:
				_launch(up)
			state = State.AIR
			_air_time += delta
		_was_on_floor = on_floor
		var blended_normal: Vector3 = display_normal.lerp(normal, clampf(DISPLAY_NORMAL_SPEED * delta, 0.0, 1.0))
		display_normal = blended_normal.normalized() if blended_normal.length_squared() > 0.0001 else normal

		if on_floor:
			_roll(motion, sprint, normal, delta)
		else:
			_fly(motion, grind_held, up, delta)

	locomotion_blend_requested.emit(LOCOMOTION_BLEND_PATH, motion.y)
	var lean_up: Vector3 = surface_up()
	_tilt_model(lean_up, MODEL_TILT_SPEED if lean_up != up or state != State.AIR else AIR_TILT_SPEED, delta)

	if state == State.RAIL:
		_pose_model()
	else:
		var intended: Vector3 = player.velocity
		player.update_movement_and_rotation(delta)
		if player.is_on_floor():
			# move_and_slide strips the vertical part of a grounded velocity, which would bleed off a descent down a
			# transition frame by frame; keep the intended speed along the surface (and any ollie push off it)
			var floor_normal: Vector3 = player.get_floor_normal()
			player.velocity = intended.slide(floor_normal) + floor_normal * maxf(intended.dot(floor_normal), 0.0)
		if player.is_on_wall() and state == State.GROUND:
			_bounce_off_wall(player.get_wall_normal())
	if balance_meter:
		balance_meter.visible = balance != null and player.is_multiplayer_authority()
		if balance:
			balance_meter.lean = balance.lean
	_refresh_hud()
	_old_position = player.global_position
	_update_sounds()
	camera.follow(delta)


## On the ground: THUG do_on_ground_physics. The velocity is rotated into the surface with its speed kept, gravity
## along the surface slows a climb, a turn rotates the velocity with the facing, sideways velocity is removed so
## the board never slides, and a kick, a brake or the wind changes the speed.
func _roll(motion: Vector2, sprint: bool, normal: Vector3, delta: float) -> void:
	var up: Vector3 = player.up_direction
	var gravity: Vector3 = -up * GROUND_GRAVITY
	var lift: float = maxf(player.velocity.dot(normal), 0.0) # an ollie's push off the surface, kept so the board leaves it
	var velocity: Vector3 = rotate_to_plane(player.velocity - normal * lift, normal)
	velocity += gravity.slide(normal) * delta

	# Down is the sharp turn while Left or Right is held at speed, and the brake otherwise (is_trying_to_brake)
	var down: bool = motion.y < 0.0 and balance == null
	var speed: float = (player.velocity - normal * lift).length()
	var braking: bool = down and (motion.x == 0.0 or speed < SLOW_SPEED)
	var forward: Vector3 = player.orientation.basis.z.slide(normal)
	if forward.length_squared() < 0.001:
		forward = velocity.slide(normal)
	var has_forward: bool = forward.length_squared() > 0.001
	if has_forward:
		forward = forward.normalized()

	# Turning: a constant rate about the surface normal, ramped in from a standstill (handle_ground_rotation)
	speed = velocity.length()
	if motion.x != 0.0 and balance == null:
		_turn_hold += delta
		var rate: float = SHARP_TURN_RATE if down else TURN_RATE
		if speed < STOPPED_SPEED:
			rate *= clampf(_turn_hold / STOPPED_TURN_RAMP_TIME, 0.0, 1.0)
		var rot: float = -motion.x * rate * delta
		player.orientation.basis = Basis(normal, rot) * player.orientation.basis
		velocity = velocity.rotated(normal, rot)
		if has_forward:
			forward = forward.rotated(normal, rot)
	else:
		_turn_hold = 0.0

	# Rolling backwards turns the skater round (flip_if_skating_backwards)
	if has_forward and not braking and speed > FLIP_SPEED and velocity.dot(forward) < 0.0:
		player.orientation.basis = Basis(normal, PI) * player.orientation.basis
		player.model_pitch = -player.model_pitch
		forward = -forward

	# Kick, brake, drag: on the speed alone (do_kick, do_brake, the friction block and limit_speed)
	var kicking: bool = motion.y > 0.0 or player.current_locomotion_node == KICK_PUSH
	if braking:
		speed = 0.0 if speed < 2.0 * BRAKE * delta else speed - BRAKE * delta
	elif kicking and balance == null:
		var cap: float = CROUCH_KICK_MAX_SPEED if sprint else KICK_MAX_SPEED
		if speed < cap:
			speed = minf(speed + (CROUCH_KICK_ACCELERATION if sprint else KICK_ACCELERATION) * delta, cap)
	speed -= (CROUCH_WIND_DRAG if sprint else WIND_DRAG) * speed * speed * delta
	if speed > MAX_SPEED:
		speed -= HEAVY_DRAG * speed * speed * delta
	speed = clampf(speed, 0.0, MAX_MAX_SPEED)

	# The board never slides: the speed goes along the facing (remove_sideways_velocity)
	if has_forward:
		velocity = forward * speed * (-1.0 if velocity.dot(forward) < 0.0 else 1.0)
	elif velocity.length_squared() > 0.000001:
		velocity = velocity.normalized() * speed

	if balance and trick != "grind" and (speed < MANUAL_MIN_SPEED or balance.update(delta, motion.y)):
		_bail()
		velocity *= BAIL_SPEED_SCALE
	player.velocity = velocity + normal * lift + normal * minf(gravity.dot(normal), 0.0) * delta


## A wall met on the ground: THUG bounce_off_wall. The velocity and the facing are turned to run along the wall,
## and the speed drops by how square-on the hit was, to nothing head-on, so the board never grinds along a wall.
func _bounce_off_wall(wall_normal: Vector3) -> void:
	var up: Vector3 = player.up_direction
	var velocity: Vector3 = player.velocity.slide(up)
	var speed: float = velocity.length()
	if speed < 0.01:
		return
	var incidence: float = asin(clampf(absf(velocity.normalized().dot(wall_normal)), 0.0, 1.0))
	if incidence > WALL_BOUNCE_DONT_SLOW_ANGLE:
		speed *= 1.0 - (incidence - WALL_BOUNCE_DONT_SLOW_ANGLE) / (PI * 0.5 - WALL_BOUNCE_DONT_SLOW_ANGLE)
	var along: Vector3 = velocity.slide(wall_normal)
	if along.length_squared() < 0.0001 or speed < 0.05:
		player.velocity = player.velocity - velocity
		return
	along = along.normalized()
	player.velocity = along * speed + up * player.velocity.dot(up)
	player.rotate_model_to_direction(along)
	player.global_position += wall_normal * 0.02


## Pops the board. [param held] seconds on the button make the pop linear between the tap and the full hold (THUG
## do_jump: jump speed lerps over skater_max_tense_time), a downward speed is thrown away first so a jump down a
## slope is not stolen, and the pop off a vert wall is the smaller range. A late pop while already falling back
## into the ramp pushes off the wall into the pipe and ends the vert air. Off a rail the pop leaves the rail.
func _ollie(held: float = MAX_TENSE_TIME) -> void:
	var up: Vector3 = player.up_direction
	var charge: float = clampf(held / MAX_TENSE_TIME, 0.0, 1.0)
	if state == State.RAIL:
		_leave_rail(RAIL_JUMP_REGRIND_TIME)
		player.velocity += up * lerpf(OLLIE_MIN_SPEED, OLLIE_MAX_SPEED, charge)
		_ollie_grace = OLLIE_GRACE
		_play_board("ollie")
		return
	if vert_normal != Vector3.ZERO and not player.is_on_floor() and player.velocity.dot(up) < 0.0:
		player.velocity += vert_normal * lerpf(OLLIE_MIN_SPEED, OLLIE_MAX_SPEED, charge)
		vert_out = Vector3.ZERO
		vert_normal = Vector3.ZERO
		return
	var from_vert: bool = player.is_on_floor() and vert_launch_direction(player.get_floor_normal(), up) != Vector3.ZERO
	var pop: float = lerpf(VERT_OLLIE_MIN_SPEED, VERT_OLLIE_MAX_SPEED, charge) if from_vert else lerpf(OLLIE_MIN_SPEED, OLLIE_MAX_SPEED, charge)
	_end_trick(false)
	_play_board("ollie")
	player.velocity += up * (pop - minf(player.velocity.dot(up), 0.0))
	if player.is_on_floor() and _ollie_grace <= 0.0:
		# Off the ground right now: decide vert from the surface under the board, and keep the wall from catching the pop
		_ollie_grace = OLLIE_GRACE
		_was_on_floor = false
		state = State.AIR
		_launch(up)


## Airborne: THUG do_in_air_physics. With Grind held a rail is looked for along this tick's move; Left and Right
## spin the skater once held past a tap (Physics_Air_No_Rotate_Time, then a ramp); gravity does the rest, and in
## vert air the skater is held in the wall's vertical plane (tracking) so nothing carries them over the pipe.
func _fly(motion: Vector2, grind_held: bool, up: Vector3, delta: float) -> void:
	if grind_held and _now() >= _rerail_at and _try_rail():
		return
	if motion.x != 0.0:
		_air_spin_hold += delta
		var ramp: float = clampf((_air_spin_hold - AIR_NO_ROTATE_TIME) / (AIR_RAMP_ROTATE_TIME - AIR_NO_ROTATE_TIME), 0.0, 1.0)
		if ramp > 0.0:
			var turn: float = -motion.x * AIR_SPIN_SPEED * ramp * delta
			player.orientation.basis = Basis(up, turn) * player.orientation.basis
			_spin_tally += rad_to_deg(turn)
	else:
		_air_spin_hold = 0.0
	var gravity: Vector3 = -up * AIR_GRAVITY
	if vert_normal != Vector3.ZERO and not _wall_still_behind():
		vert_out = Vector3.ZERO # off the end of the wall: THUG drops tracking and the skater recovers as regular air
		vert_normal = Vector3.ZERO
	if vert_normal != Vector3.ZERO:
		var drift: float = (player.global_position - _vert_point).dot(vert_normal)
		if not is_zero_approx(drift):
			player.global_position -= vert_normal * drift
		player.velocity = player.velocity.slide(vert_normal) + gravity / VERT_HANG * delta
	else:
		player.velocity += gravity / AIR_HANG * delta


## Whether the wall the skater launched from is still behind them at the launch height (THUG's tracking feeler).
func _wall_still_behind() -> bool:
	var from: Vector3 = Vector3(player.global_position.x, _vert_point.y, player.global_position.z) + vert_normal * 0.5
	var to: Vector3 = from - vert_normal * VERT_TRACK_REACH
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, player.collision_mask, [player.get_rid()])
	return not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Leaving the floor. Off a vert wall the velocity is rotated into the wall's vertical plane with its speed kept and
## the plane is remembered for tracking. Holding forward at the lip breaks vert instead: a share of the speed goes
## over the deck and it is regular air.
func _launch(up: Vector3) -> void:
	_air_spin_hold = 0.0
	_spin_tally = 0.0
	_landed_from_vert_at = -1.0
	if balance and trick != "grind":
		_end_trick(false)
	if vert_normal != Vector3.ZERO:
		return # a brush against the wall mid vert air, not a new launch
	var out: Vector3 = vert_launch_direction(last_floor_normal, up)
	vert_out = Vector3.ZERO
	vert_normal = Vector3.ZERO
	if out == Vector3.ZERO:
		return
	if player.player_input.motion.y > 0.5:
		var speed: float = player.velocity.length()
		player.velocity += out * speed * BREAK_VERT_SPEED_SCALE
		player.velocity -= up * player.velocity.dot(up) * (1.0 - BREAK_VERT_UP_SCALE)
		return
	vert_out = out
	vert_normal = -out
	player.global_position += vert_normal * VERT_PUSH_OUT
	_vert_point = player.global_position
	player.velocity = vert_launch_velocity(player.velocity, vert_normal)


## Touching down: face the way the board is rolling, whatever the spin left the skater at (THUG flips a skater
## rolling backwards on touchdown, lean intact). The velocity itself is projected onto the ground by the body.
func _land(normal: Vector3) -> void:
	if _air_time < MIN_AIR_TIME:
		return # contact flicker on a steep transition; the vert air, if any, carries on
	var from_vert: bool = vert_normal != Vector3.ZERO
	vert_out = Vector3.ZERO
	vert_normal = Vector3.ZERO
	_air_spin_hold = 0.0
	_settle_landing(from_vert)
	var rolling: Vector3 = player.velocity.slide(normal)
	if rolling.length() > 1.0:
		var reversed: bool = player.orientation.basis.z.slide(player.up_direction).dot(rolling.slide(player.up_direction)) < 0.0
		player.rotate_model_to_direction(rolling)
		if reversed:
			player.model_pitch = -player.model_pitch


# --- Rails --------------------------------------------------------------------------------------------------------

## Looks for a rail along this tick's move (THUG CRailManager::StickToRail): the closest rail within
## [constant RAIL_MAX_SNAP], scored so one the board travels along beats one across it eight to one. Locks on when
## one is found and returns true.
func _try_rail() -> bool:
	var up: Vector3 = player.up_direction
	var from: Vector3 = _old_position
	var to: Vector3 = player.global_position
	var move: Vector3 = (to - from).slide(up)
	var best_rail: Rail = null
	var best_hit: Dictionary = {}
	var best_score: float = INF
	for node: Node in get_tree().get_nodes_in_group("rails"):
		var candidate: Rail = node as Rail
		if candidate == null or not candidate.is_inside_tree():
			continue
		var hit: Dictionary = candidate.closest_to_segment(from, to)
		if hit.is_empty():
			continue
		var direction: Vector3 = (hit["direction"] as Vector3).slide(up)
		var dot: float = 1.0
		if move.length() > 0.05 and direction.length_squared() > 0.0001:
			dot = absf(direction.normalized().dot(move.normalized()))
		var distance: float = hit["distance"]
		if distance * (2.0 - dot) > RAIL_MAX_SNAP:
			continue
		var score: float = distance * (RAIL_PARALLEL_WEIGHT + 1.0 - dot)
		if score < best_score:
			best_score = score
			best_rail = candidate
			best_hit = hit
	if best_rail == null:
		return false
	_got_rail(best_rail, best_hit)
	return true


## Locks onto [param on] at [param hit] (THUG got_rail): the horizontal speed goes along the rail the way the board
## was heading, plus the rail's boost, the skater faces along it, and the grind's balance starts.
func _got_rail(on: Rail, hit: Dictionary) -> void:
	var up: Vector3 = player.up_direction
	var direction: Vector3 = hit["direction"]
	var horizontal: Vector3 = player.velocity.slide(up)
	if horizontal.length() < 0.1:
		horizontal = player.orientation.basis.z.slide(up)
	var along: float = direction.dot(horizontal)
	rail = on
	rail_offset = hit["offset"]
	rail_sign = -1.0 if along < 0.0 else 1.0
	rail_speed = horizontal.length() + on.speed_boost
	vert_out = Vector3.ZERO
	vert_normal = Vector3.ZERO
	state = State.RAIL
	_was_on_floor = false
	_air_time = 0.0
	_reset_board()
	air_trick = ""
	player.global_position = hit["point"]
	player.velocity = direction * rail_sign * rail_speed
	player.model_pitch = 0.0
	player.rotate_model_to_direction(direction * rail_sign)
	_start_trick("grind")
	var grind: Array = SkateTricks.named(SkateTricks.GRINDS, SkateTricks.direction_of(_digital(player.player_input.motion)))
	tricks.add(grind[0], grind[1])
	_bank_timer = 0.0


## Riding the rail: THUG do_rail_physics. Gravity along the rail speeds a descent and slows a climb (and turns the
## board round if it stalls), the balance runs on Left and Right, and the rail ends at its last point or at a bend
## sharper than the rail allows.
func _grind(motion: Vector2, delta: float) -> void:
	if not is_instance_valid(rail) or not rail.is_inside_tree():
		_leave_rail(RAIL_REGRIND_TIME)
		return
	var direction: Vector3 = rail.direction_at(rail_offset)
	rail_speed += (-player.up_direction * RAIL_GRAVITY).dot(direction * rail_sign) * delta
	if rail_speed < 0.0:
		rail_speed = -rail_speed
		rail_sign = -rail_sign
	if balance.update(delta, motion.x):
		_bail()
		_leave_rail(RAIL_REGRIND_TIME)
		return
	rail_offset += rail_speed * rail_sign * delta
	if rail_offset <= 0.0 or rail_offset >= rail.length():
		rail_offset = clampf(rail_offset, 0.0, rail.length())
		player.global_position = rail.point_at(rail_offset)
		player.velocity = direction * rail_sign * rail_speed
		_leave_rail(RAIL_REGRIND_TIME)
		return
	var ahead: Vector3 = rail.direction_at(rail_offset)
	if ahead.angle_to(direction) > deg_to_rad(rail.leave_angle_degrees):
		player.velocity = direction * rail_sign * rail_speed
		_leave_rail(RAIL_REGRIND_TIME)
		return
	player.global_position = rail.point_at(rail_offset)
	player.velocity = ahead * rail_sign * rail_speed
	player.turn_model_toward_direction(ahead * rail_sign, delta)


## Off the rail into the air, lifted a hair so the rail does not take the board straight back, and no rail for
## [param regrind_time] seconds (THUG skate_off_rail and the rerail times).
func _leave_rail(regrind_time: float) -> void:
	if trick == "grind":
		_end_trick(false)
	rail = null
	state = State.AIR
	_air_time = 0.0
	_was_on_floor = false
	_rerail_at = _now() + regrind_time
	player.global_position += player.up_direction * RAIL_HOP


# --- Balance tricks -----------------------------------------------------------------------------------------------

func _start_trick(kind: String) -> void:
	balance = SkateBalance.new()
	balance.setup(kind == "grind")
	trick = kind
	if SkateTricks.MANUALS.has(kind):
		var manual: Array = SkateTricks.MANUALS[kind]
		tricks.add(manual[0], manual[1])
		_bank_timer = 0.0
	trick_started.emit(kind)


func _end_trick(bailed: bool) -> void:
	if balance == null:
		return
	var kind: String = trick
	balance = null
	trick = ""
	trick_ended.emit(kind, bailed)


## The needle went off the meter: the trick is over, most of the speed is gone, and the rider is a passenger for
## [constant BAIL_TIME] (THUG's bail is an animation over the same physics; there is no ragdoll here yet).
func _bail() -> void:
	_end_trick(true)
	air_trick = ""
	tricks.bail()
	combo_lost.emit()
	player.velocity = player.velocity.slide(player.up_direction) * BAIL_SPEED_SCALE + player.up_direction * minf(player.velocity.dot(player.up_direction), 0.0)
	_bail_timer = BAIL_TIME
	_tense_since = -1.0


# --- Tricks and the score -----------------------------------------------------------------------------------------

## Starts a flip or a grab in the air: [param named] is [name, points] from the trick tables.
func _start_air_trick(kind: String, named: Array) -> void:
	air_trick = named[0]
	_air_trick_kind = kind
	_air_trick_time = 0.0
	tricks.add(named[0], named[1])
	_bank_timer = 0.0
	if kind == "flip":
		_play_board(animation_name_for(named[0]))


## The board's animation for a trick name: "Pop Shove-It" is "pop_shove_it".
static func animation_name_for(trick_name: String) -> String:
	return trick_name.to_lower().replace(" ", "_").replace("-", "_")


## Plays [param animation] on the board's mesh when the board has it; the mesh is put back level first.
func _play_board(animation: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation):
		return
	animation_player.play(animation)


## Puts the mesh back level: the end of a flip on landing, or a bail mid-flip.
func _reset_board() -> void:
	if animation_player and animation_player.is_playing():
		animation_player.stop()
	if board_pivot:
		board_pivot.rotation = Vector3.ZERO


## Runs the timers behind the combo each tick: the air trick's time, the points a hold earns, and the grace after a
## landing at whose end the combo is banked.
func _tick_tricks(delta: float) -> void:
	if air_trick != "":
		_air_trick_time += delta
		if _air_trick_kind == "grab":
			var grab: StringName = _action(keyboard_grab_action, pad_grab_action)
			if Input.is_action_pressed(grab):
				tricks.hold(delta)
			elif _air_trick_time >= SkateTricks.GRAB_MIN_TIME:
				air_trick = "" # let go: the grab is done and a landing is clean
	if balance != null:
		tricks.hold(delta)
	if _bank_timer > 0.0:
		_bank_timer -= delta
		if _bank_timer <= 0.0 and balance == null and state == State.GROUND and not tricks.combo.is_empty():
			combo_banked.emit(tricks.land_clean())


## A landing: a flip still turning is a bail, a spin far from a half turn is a bail, otherwise the spin is counted,
## a vert landing opens the revert window, and the combo waits [constant BANK_GRACE] for a manual or a revert
## before it is banked. THUG's physics never refuses a landing; this is its Landed script's decision.
func _settle_landing(from_vert: bool) -> void:
	_reset_board()
	var sloppy_spin: bool = SkateTricks.spin_is_sloppy(_spin_tally)
	var mid_flip: bool = air_trick != "" and _air_trick_kind == "flip" and _air_trick_time < SkateTricks.FLIP_TIME
	if mid_flip or sloppy_spin:
		air_trick = ""
		_bail()
		return
	air_trick = ""
	tricks.add_spin(_spin_tally)
	_spin_tally = 0.0
	_landed_from_vert_at = _now() if from_vert else -1.0
	if not tricks.combo.is_empty():
		_bank_timer = BANK_GRACE


## Puts the combo, its worth and the score on the board's HUD for the rider.
func _refresh_hud() -> void:
	if trick_line == null:
		return
	var mine: bool = player != null and player.is_multiplayer_authority()
	trick_line.visible = mine and not tricks.combo.is_empty()
	trick_total.visible = trick_line.visible
	score_label.visible = mine
	trick_line.text = tricks.combo_text()
	trick_total.text = tricks.total_text()
	score_label.text = "SCORE %s" % SkateTricks._with_commas(tricks.score)


# --- Model --------------------------------------------------------------------------------------------------------

## The up the skater is leaning to and the camera hangs off: the smoothed floor normal on the ground and through
## contact flicker on a steep transition, the wall's normal through vert air, world up in regular air and on a rail.
func surface_up() -> Vector3:
	if player == null:
		return Vector3.UP
	if state == State.RAIL:
		return player.up_direction
	if player.is_on_floor() and _ollie_grace <= 0.0 or _air_time < MIN_AIR_TIME and vert_normal == Vector3.ZERO and not _was_on_floor:
		return display_normal
	if vert_normal != Vector3.ZERO:
		return last_floor_normal if _air_time < MIN_AIR_TIME else vert_normal
	return player.up_direction


## Leans the model (pivoting at the feet) so its up matches [param surface_up], at [param speed] per second, and
## pitches it with the meter in a manual.
func _tilt_model(surface_up_: Vector3, speed: float, delta: float) -> void:
	var local_up: Vector3 = player.orientation.basis.inverse() * surface_up_
	var target_pitch: float = atan2(local_up.z, local_up.y)
	if balance and trick != "grind":
		target_pitch += balance.lean * MANUAL_TILT * (1.0 if trick == "manual" else -1.0)
	player.model_pitch = lerp_angle(player.model_pitch, target_pitch, clampf(speed * delta, 0.0, 1.0))


## On a rail the body is placed by hand rather than by move_and_slide, so the model is posed the way
## [method Player.update_movement_and_rotation] would pose it.
func _pose_model() -> void:
	player.orientation.origin = Vector3.ZERO
	player.orientation = player.orientation.orthonormalized()
	player.player_model.global_transform.basis = player.orientation.basis
	player.player_model.transform.origin = player.initial_player_model_transform.origin


## Horizontal direction over the deck of a wall steep enough to be vert (away from the face the skater rode up),
## or ZERO when leaving flatter ground.
static func vert_launch_direction(floor_normal: Vector3, up: Vector3) -> Vector3:
	var into_pipe: Vector3 = floor_normal.slide(up)
	if floor_normal.angle_to(up) < VERT_ANGLE or into_pipe.length_squared() < 0.0001:
		return Vector3.ZERO
	return -into_pipe.normalized()


## The launch velocity rotated into the wall's vertical plane (normal [param wall_normal]) with its speed kept,
## as THUG's RotateToPlane does: speed that was heading over the deck becomes climb.
static func vert_launch_velocity(velocity: Vector3, wall_normal: Vector3) -> Vector3:
	return rotate_to_plane(velocity, wall_normal)


## [param velocity] turned into the plane with normal [param normal] with its length kept (THUG's
## Mth::Vector::RotateToPlane), where a projection would lose the part that pointed out of the plane.
static func rotate_to_plane(velocity: Vector3, normal: Vector3) -> Vector3:
	var in_plane: Vector3 = velocity.slide(normal)
	if in_plane.length_squared() < 0.000001:
		return velocity
	return in_plane.normalized() * velocity.length()


## Rideable contract: label names on the Player's controls to their text while skating.
func get_contextual_controls(input_type_: int) -> Dictionary:
	return {
		"left_joystick": "Steer / Balance",
		"right_joystick": "Camera",
		"joypad_button_3": "Ollie",
		"joypad_button_0": "Grind",
		"joypad_button_2": "Flip",
		"joypad_button_1": "Grab / Push",
		"joypad_axis_4_plus": "Revert",
		"joypad_axis_5_plus": "Revert",
		"key_k" if input_type_ == Controls.InputType.KEYBOARD_MOUSE else "joypad_button_12": "Dismount",
	}


## The action for the rider's current input device.
func _action(keyboard_action: StringName, pad_action: StringName) -> StringName:
	if input_type == Controls.InputType.KEYBOARD_MOUSE:
		return keyboard_action
	return pad_action


# --- Sounds -------------------------------------------------------------------------------------------------------

## Roll, ollie and landing sounds for the surface under the board.
func _update_sounds() -> void:
	var is_on_floor: bool = player.is_on_floor()
	var is_jumping: bool = player.is_jumping
	var is_falling: bool = player.is_falling
	var target_roll_sfx: AudioStreamPlayer3D = _get_target_roll_sfx()
	if is_jumping and not _sfx_was_jumping:
		stop_all_roll_sounds()
		if target_roll_sfx and not sfx_ollie.playing:
			sfx_ollie.play()
	if is_on_floor and (not _sfx_was_on_floor or _sfx_was_jumping or _sfx_was_falling):
		if target_roll_sfx and not sfx_land.playing:
			sfx_land.play()
	var h_speed: float = player.velocity.slide(player.up_direction).length()
	if is_on_floor and h_speed > 0.1:
		_play_roll_sfx(target_roll_sfx)
	else:
		stop_all_roll_sounds()
	_sfx_was_on_floor = is_on_floor
	_sfx_was_jumping = is_jumping
	_sfx_was_falling = is_falling


func _get_target_roll_sfx() -> AudioStreamPlayer3D:
	if ground_ray.is_colliding():
		var collider: Node3D = ground_ray.get_collider() as Node3D
		if collider:
			if collider.is_in_group("WOOD"):
				return sfx_roll_on_wood
			elif collider.is_in_group("STONE") or collider.is_in_group("COBBLESTONE"):
				return sfx_roll_on_cobblestone
			elif collider.is_in_group("CONCRETE"):
				return sfx_roll_on_concrete
	return null


func _play_roll_sfx(target_sfx: AudioStreamPlayer3D) -> void:
	# Don't play roll sound while Ollie or Land SFX is actively playing
	if not target_sfx or sfx_ollie.playing or sfx_land.playing:
		stop_all_roll_sounds()
		return
	if target_sfx.playing:
		return
	stop_all_roll_sounds()
	target_sfx.play()


func stop_all_roll_sounds() -> void:
	sfx_roll_on_cobblestone.stop()
	sfx_roll_on_concrete.stop()
	sfx_roll_on_wood.stop()
