class_name SkateboardCamera
extends Camera3D
## The THPS camera, after Neversoft's CSkaterCameraComponent::Update in the Tony Hawk's Underground source
## (Code/Gel/Components/SkaterCameraComponent.cpp). It belongs to the [Skateboard]; the rider's Riding state
## makes it current while the board is ridden and takes the view back on dismount.
##
## Every physics tick, after the board has moved the skater: a target frame is built from the way the skater
## travels (the velocity, with the part along the ground flattened by four fifths on the ground and fully in
## the air) and the skater's up (the smoothed ground normal, so the view pitches and rolls up a transition
## with them; world up in plain air), tilted down a little and more in the air; the camera's frame turns toward
## it by a fixed fraction each sixtieth of a second, with a limiter on how far it may swing in one frame; a
## tripod lags the skater's position by its own fractions, sideways and up; the camera sits behind the frame
## and above the skater from the tripod and is aimed at the true skater, so the lag reads as distance and
## speed. In vert air the target forward is straight down, the tripod stops lagging, and the frame's up is the
## wall's normal, so the camera rides overhead with the skater and watches them go up and come back down the
## same wall; for a moment after the landing it swings back behind them faster. On a rail it zooms in a little
## and rolls with the balance. THUG's numbers live in physics.q, which is not in the source; the values here
## are its constructor fallbacks where it has them and set by feel against its footage where it does not.

const VERT_AIR_LANDED_TIME: float = 10.0 / 60.0 ## VERT_AIR_LANDED_TIME: the faster swing back after a vert landing lasts this long.
const VERT_CAM_DELAY: float = 0.2 ## Vert air becomes the vert cam once the chance to break vert has passed (Skater_Vert_Allow_break_Time).
const TILT_MAX: float = deg_to_rad(20.0) ## TILT_MAX: the extra downward tilt reached in the air.
const TILT_INCREMENT: float = deg_to_rad(40.0) ## Per second, in the air.
const TILT_RESTORE: float = deg_to_rad(160.0) ## Per second, back on the ground.
const CAMERA_SLERP_STOP: float = 0.9999 ## Within this of the target the frame is left alone.
const LEAN_TO_CAMERA_LEAN: float = PI / 6.0 ## A full grind lean rolls the view this far.
const PERFECT_ABOVE: float = 0.08 ## SKATERCAMERACOMPONENT_PERFECT_ABOVE, 3 in: what "above" tends to as the zoom closes.
const MIN_DISTANCE: float = 0.3 ## 11.9 in: the collision never brings the camera closer to the focus than this.
const WALL_MARGIN: float = 0.05 ## 2 in kept off whatever the camera ray hit.
const SIDE_FEELER: float = 0.2 ## 8 in feelers either side of the camera.

@export var behind: float = 3.6 ## Metres behind the frame the camera sits ("behind", a physics.q value).
@export var above: float = 1.4 ## Metres above the skater's feet, along their up, both for the camera and for what it looks at ("above").
@export var tilt: float = deg_to_rad(8.0) ## Resting downward tilt of the frame ("tilt").
@export var field_of_view: float = 55.0 ## Vertical degrees; THUG's "horiz_fov" of about 72 at 16:10.
@export var slerp: float = 0.12 ## Fraction of the way to the target frame per sixtieth of a second ("slerp").
@export var vert_air_slerp: float = 0.08 ## The same in vert air ("vert_air_slerp").
@export var vert_air_landed_slerp: float = 0.3 ## And just after a vert landing ("vert_air_landed_slerp").
@export var lerp_xz: float = 0.25 ## Fraction of the way the tripod moves toward the skater sideways per sixtieth ("lerp_xz").
@export var lerp_y: float = 0.5 ## And up ("lerp_y").
@export var vert_air_lerp_xz: float = 1.0 ## In vert air the tripod is on the skater ("vert_air_lerp_xz").
@export var vert_air_lerp_y: float = 1.0 ## ("vert_air_lerp_y")
@export var grind_lerp: float = 0.1 ## How fast the roll follows the grind lean ("grind_lerp").
@export var zoom_lerp: float = 0.0625 ## How fast the zoom moves ("zoom_lerp").
@export var grind_zoom: float = 0.8 ## Behind is this much of itself on a rail ("grind_zoom").
@export var lookaround_max: Vector2 = Vector2(deg_to_rad(120.0), deg_to_rad(45.0)) ## Manual look is an offset on the frame (heading, tilt), not a free camera.
@export var lookaround_return: float = 3.0 ## Per-second rate the offset eases back once the look input stops.

var player: Player
var board: Node3D
var lookaround: Vector2 = Vector2.ZERO ## Manual look offset: heading about the skater's up, tilt about the frame's right.
var tripod: Vector3 = Vector3.ZERO ## The lagging pivot the camera hangs off, in world space.
var frame: Basis = Basis.IDENTITY ## The camera frame (-Z forward), eased toward its target each tick.
var _tilt_addition: float = 0.0
var _landed_timer: float = 0.0
var _last_dot: float = 1.0
var _lean: float = 0.0
var _zoom: float = 1.0
var _instant: int = 0 ## Ticks left in which the camera snaps rather than eases (after a teleport).

@onready var look_return_timer: Timer = $LookReturnTimer ## Running while the lookaround holds instead of easing back.


func _ready() -> void:
	top_level = true
	set_process(false)
	set_process_unhandled_input(false)


## Takes over from [param rider]'s own camera, starting behind them so the handover does not cut across the park.
func begin(rider: Player, ridden: Node3D) -> void:
	player = rider
	board = ridden
	fov = field_of_view
	tripod = rider.global_position
	lookaround = Vector2.ZERO
	_tilt_addition = 0.0
	_landed_timer = 0.0
	_last_dot = 1.0
	_lean = 0.0
	_zoom = 1.0
	_instant = 3
	frame = Basis.looking_at(-rider.orientation.basis.z if rider.orientation.basis.z.length_squared() > 0.5 else Vector3.FORWARD, Vector3.UP)
	set_process(true)
	set_process_unhandled_input(true)
	follow(0.0)


## Stops following; the rider's own camera is made current by their Riding state.
func end() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	player = null
	board = null


func _unhandled_input(event: InputEvent) -> void:
	if not current or player == null or player.is_paused: return
	if event is InputEventMouseMotion and (DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		var sensitivity: float = player.camera.get("mouse_sensitivity") if player.camera.get("mouse_sensitivity") != null else 0.1
		_lookaround_input(-event.relative * sensitivity)


func _process(delta: float) -> void:
	if not current or player == null or player.is_paused: return
	var joypad: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joypad != Vector2.ZERO:
		var sensitivity: float = player.camera.get("joypad_sensitivity") if player.camera.get("joypad_sensitivity") != null else 100.0
		_lookaround_input(-joypad * sensitivity * delta)


func _lookaround_input(degrees: Vector2) -> void:
	lookaround += Vector2(deg_to_rad(degrees.x), deg_to_rad(degrees.y))
	lookaround = lookaround.clamp(-lookaround_max, lookaround_max)
	look_return_timer.start()


## THUG's GetTimeAdjustedSlerp: a per-sixtieth fraction [param fraction] for a tick of [param delta] seconds, so the
## lag distance at a steady speed is the same at any frame rate.
static func time_adjusted(fraction: float, delta: float) -> float:
	var t: float = delta * 60.0
	return t * fraction / (1.0 - fraction + t * fraction)


## Whether the vert cam is on: vert air once the chance to break vert has passed.
func is_vert_cam() -> bool:
	return board != null and board.get("vert_normal") != Vector3.ZERO and not player.is_on_floor() and float(board.get("_air_time")) >= VERT_CAM_DELAY


## Places the camera for this physics tick; the board calls it after it has moved the skater.
func follow(delta: float) -> void:
	if player == null or board == null: return
	var instantly: bool = _instant > 0 or delta <= 0.0
	_instant = maxi(_instant - 1, 0)
	var on_floor: bool = player.is_on_floor()
	var state: int = board.get("state")
	var on_rail: bool = state == Skateboard.State.RAIL
	var in_air: bool = state == Skateboard.State.AIR
	var vert_cam: bool = is_vert_cam()
	var skater_up: Vector3 = board.call("surface_up")

	# The target frame: forward from the travel, up from the skater (world up in plain air)
	var forward: Vector3
	var up_hint: Vector3 = Vector3.UP if in_air and not vert_cam else skater_up
	var velocity: Vector3 = player.velocity
	if vert_cam:
		forward = -player.up_direction
		lookaround = Vector2.ZERO
	elif velocity.slide(Vector3.UP).length() > 0.1:
		forward = velocity.normalized()
		var normal: Vector3 = Vector3.UP if in_air else board.get("display_normal")
		forward -= normal * (forward.dot(normal) if in_air else 0.8 * forward.dot(normal))
		if forward.length_squared() < 0.0001:
			forward = velocity.normalized()
		forward = forward.normalized()
	else:
		forward = player.orientation.basis.z
	if absf(forward.dot(up_hint)) > 0.999:
		up_hint = frame.y
	var target: Basis = Basis.looking_at(forward, up_hint)

	# Tilt down: the resting tilt, more in the air, none in the vert cam; then the lookaround
	if in_air and not vert_cam:
		_tilt_addition = minf(_tilt_addition + TILT_INCREMENT * delta, TILT_MAX)
	else:
		_tilt_addition = maxf(_tilt_addition - TILT_RESTORE * delta, 0.0)
	target = target.rotated(target.y, lookaround.x)
	if not vert_cam:
		target = target.rotated(target.x, -(tilt + _tilt_addition))
	target = target.rotated(target.x, lookaround.y)
	if look_return_timer.is_stopped():
		lookaround = lookaround.move_toward(Vector2.ZERO, lookaround_return * delta)

	# Ease the frame toward the target, faster for a moment after a vert landing, with the swing limited
	var current_at: Vector3 = -frame.z
	if instantly:
		frame = target
	elif frame.x.dot(target.x) > CAMERA_SLERP_STOP and frame.y.dot(target.y) > CAMERA_SLERP_STOP and frame.z.dot(target.z) > CAMERA_SLERP_STOP:
		pass
	else:
		var from: Quaternion = frame.get_rotation_quaternion()
		var to: Quaternion = target.get_rotation_quaternion()
		if vert_cam:
			frame = Basis(from.slerp(to, time_adjusted(vert_air_slerp, delta)))
			_landed_timer = VERT_AIR_LANDED_TIME
		elif on_floor and _landed_timer >= delta:
			_landed_timer -= delta
			frame = Basis(from.slerp(to, time_adjusted(vert_air_landed_slerp, delta)))
		else:
			_landed_timer = 0.0
			frame = Basis(from.slerp(to, time_adjusted(slerp, delta)))
			var this_dot: float = current_at.dot(-frame.z)
			if this_dot < _last_dot * 0.9998:
				var eased: float = slerp * (this_dot / (_last_dot * 0.9998))
				frame = Basis(from.slerp(to, time_adjusted(maxf(eased, 0.0), delta)))
				this_dot = _last_dot * 0.9998
			_last_dot = this_dot

	# The tripod lags the skater, except in vert air, where it rides with them
	var target_pos: Vector3 = player.global_position
	if instantly:
		tripod = target_pos
	else:
		var t_xz: float = time_adjusted(vert_air_lerp_xz if vert_cam else lerp_xz, delta)
		var t_y: float = time_adjusted(vert_air_lerp_y if vert_cam else lerp_y, delta)
		tripod = Vector3(lerpf(tripod.x, target_pos.x, t_xz), lerpf(tripod.y, target_pos.y, t_y), lerpf(tripod.z, target_pos.z, t_xz))

	# Zoom in a little on a rail; above tends to the perfect height as the zoom closes
	var target_zoom: float = grind_zoom if on_rail else 1.0
	_zoom = target_zoom if instantly else _zoom + (target_zoom - _zoom) * time_adjusted(zoom_lerp, delta)
	var zoomed_behind: float = behind * _zoom
	var zoomed_above: float = PERFECT_ABOVE + (above - PERFECT_ABOVE) * _zoom if _zoom < 1.0 else above

	# Behind the frame, above the skater, aimed at the true skater; the grind lean rolls the view
	var focus: Vector3 = player.global_position + skater_up * zoomed_above
	var camera_position: Vector3 = tripod + frame.z * zoomed_behind + skater_up * zoomed_above
	var lean_target: float = 0.0
	if on_rail and board.get("balance") != null:
		lean_target = float(board.get("balance").lean) * LEAN_TO_CAMERA_LEAN
	_lean = lean_target if instantly else _lean + (lean_target - _lean) * time_adjusted(grind_lerp, delta)
	camera_position = _keep_out_of_walls(focus, camera_position)
	var to_focus: Vector3 = focus - camera_position
	if to_focus.length_squared() < 0.0001:
		return
	var aim_up: Vector3 = frame.y
	if absf(to_focus.normalized().dot(aim_up)) > 0.999:
		aim_up = skater_up if absf(to_focus.normalized().dot(skater_up)) < 0.999 else Vector3.RIGHT
	var aimed: Basis = Basis.looking_at(to_focus.normalized(), aim_up)
	if not is_zero_approx(_lean):
		aimed = aimed.rotated(aimed.z, _lean)
	global_transform = Transform3D(aimed, camera_position)


## THUG's ApplyCameraCollisionDetection: a ray from the focus to the camera pulls it in front of whatever is in
## the way, never closer than [constant MIN_DISTANCE], and feelers either side push it off a wall it is brushing.
func _keep_out_of_walls(focus: Vector3, camera_position: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var direction: Vector3 = (camera_position - focus).normalized()
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(focus, camera_position + direction * WALL_MARGIN, player.collision_mask, [player.get_rid()])
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		var distance: float = maxf(focus.distance_to(hit.position) - WALL_MARGIN, MIN_DISTANCE)
		camera_position = focus + direction * distance
	for side: float in [1.0, -1.0]:
		var sideways: Vector3 = frame.x.slide(Vector3.UP)
		if sideways.length_squared() < 0.0001:
			break
		var feeler: Vector3 = camera_position + sideways.normalized() * SIDE_FEELER * side
		query = PhysicsRayQueryParameters3D.create(camera_position, feeler, player.collision_mask, [player.get_rid()])
		hit = space.intersect_ray(query)
		if not hit.is_empty():
			camera_position -= feeler - (hit.position as Vector3)
			break
	return camera_position
