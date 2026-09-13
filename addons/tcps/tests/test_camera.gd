extends GutTest
## Purpose: the camera is THUG's. On the flat it sits behind the way the board travels, above the skater and
## tilted down; up a transition it pitches with the ramp instead of staying level and losing the skater; in
## vert air it rides overhead with the skater looking straight down, and swings back behind them on landing;
## on a rail it rolls with the lean; its lag is a fixed fraction per sixtieth of a second whatever the frame rate.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/skate_park.tscn")

var park: Node3D
var player: Player
var board: Skateboard
var camera: SkateboardCamera


func before_each() -> void:
	park = PARK_SCENE.instantiate()
	(park.get_node("MountTimer") as Timer).autostart = false
	add_child_autofree(park)
	player = park.get_node("Player")
	board = park.get_node("Skateboard")
	player.mount(board)
	await wait_physics_frames(3)
	camera = board.camera


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint"]:
		Input.action_release(action)


func _place(at: Vector3, heading: Vector3, speed: float) -> void:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(heading.x, heading.z)), Vector3(at.x, 0.02, at.z)))
	player.velocity = heading * speed
	camera._instant = 3
	var frames: int = 0
	while not (player.is_on_floor() and board.state == Skateboard.State.GROUND) and frames < 30:
		player.velocity = Vector3(heading.x * speed, player.velocity.y, heading.z * speed)
		await get_tree().physics_frame
		frames += 1
	player.velocity = heading * speed


func test_the_lag_is_the_same_distance_at_any_frame_rate() -> void:
	assert_almost_eq(SkateboardCamera.time_adjusted(0.25, 1.0 / 60.0), 0.25, 0.0001, "At sixty a sixtieth is itself")
	assert_almost_eq(SkateboardCamera.time_adjusted(0.25, 2.0 / 60.0), 0.4, 0.0001, "At thirty it is the fraction THUG's note works out")
	assert_almost_eq(SkateboardCamera.time_adjusted(0.25, 5.0 / 60.0), 0.625, 0.0001, "and at twelve")


func test_on_the_flat_the_camera_sits_behind_above_and_tilted_down() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	Input.action_press(&"move_up")
	await wait_physics_frames(90)
	var travel: Vector3 = player.velocity.normalized()
	var looking: Vector3 = -camera.global_basis.z
	assert_gt(looking.slide(Vector3.UP).normalized().dot(travel), 0.95, "The camera looks along the way the board travels")
	assert_lt(looking.y, -0.05, "tilted down a little")
	assert_gt(looking.y, -0.5, "but not much")
	var offset: Vector3 = camera.global_position - player.global_position
	assert_lt(offset.dot(travel), -camera.behind * 0.7, "From behind the skater, most of the lag distance back")
	assert_between(offset.y, camera.above * 0.5, camera.above + camera.behind * 0.5, "and up by about the above height plus the tilt")
	assert_true(camera.current, "And it is the view while riding")


## Rides the left wall of the half pipe from the flat, as a player does, and records what the camera did.
func _ride_the_left_wall() -> Dictionary:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(-1.0, 0.0)), Vector3(3.0, 0.02, -10.0)))
	player.velocity = Vector3(-8.0, 0.0, 0.0)
	camera._instant = 3
	Input.action_press(&"sprint") # THUG's crouched push: a standing push tops out below what a 3.3 m wall needs
	await wait_physics_frames(3)
	var ride: Dictionary = {"steepest_look_up": -1.0, "vert_frames": 0, "camera_above_at_peak": false, "look_at_launch": 0.0, "look_at_peak": 0.0, "tripod_gap_at_peak": 0.0, "landed": false, "behind_after_landing": false}
	var frames: int = 0
	var air_frames: int = 0
	var launched: bool = false
	while frames < 400:
		var on_transition: bool = player.is_on_floor() and player.get_floor_normal().y < 0.7
		player.player_input.motion = Vector2(0.0, 1.0) if (player.is_on_floor() and not on_transition and not launched) else Vector2.ZERO
		await get_tree().physics_frame
		frames += 1
		var looking: Vector3 = -camera.global_basis.z
		if on_transition and player.velocity.y > 2.0:
			ride.steepest_look_up = maxf(ride.steepest_look_up, looking.y)
		air_frames = 0 if player.is_on_floor() else air_frames + 1
		if board.vert_normal != Vector3.ZERO and air_frames >= 5:
			if not launched:
				ride.look_at_launch = looking.y
			launched = true
			ride.vert_frames += 1
			if absf(player.velocity.y) < 0.5:
				ride.camera_above_at_peak = camera.global_position.y > player.global_position.y + 0.5
				ride.look_at_peak = looking.y
				ride.tripod_gap_at_peak = camera.tripod.distance_to(player.global_position)
		if launched and player.is_on_floor() and air_frames == 0:
			ride.landed = true
			for i: int in 40:
				await get_tree().physics_frame
			var travel: Vector3 = player.velocity.slide(Vector3.UP).normalized()
			var after: Vector3 = -camera.global_basis.z
			ride.behind_after_landing = after.slide(Vector3.UP).normalized().dot(travel) > 0.8 and (camera.global_position - player.global_position).dot(travel) < 0.0
			break
	return ride


func test_up_a_transition_the_camera_pitches_with_the_ramp_and_rides_overhead_in_vert_air() -> void:
	var ride: Dictionary = await _ride_the_left_wall()
	assert_gt(ride.steepest_look_up, 0.1, "Climbing the wall the camera looks up the ramp with the skater, not level (THUG's frame eases at 4 percent a frame, so it is well short of the ramp's pitch)")
	assert_gt(ride.vert_frames, 5, "The board went into vert air")
	assert_true(ride.camera_above_at_peak, "At the peak the camera is above the skater")
	assert_lt(ride.look_at_peak, ride.look_at_launch - 0.2, "turning to look down at them (all the way down takes a bigger air than this wall gives)")
	assert_lt(ride.tripod_gap_at_peak, 0.5, "with the tripod riding on them, not parked at the ramp")
	assert_true(ride.landed, "The skater came back down")
	assert_true(ride.behind_after_landing, "and within two thirds of a second the camera is back behind them")


func test_on_a_rail_the_camera_rolls_with_the_lean() -> void:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(1.0, 0.0)), Vector3(-3.6, 0.9, 15.7)))
	player.velocity = Vector3(6.0, 1.0, 0.0)
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._old_position = player.global_position
	camera._instant = 3
	Input.action_press(&"action")
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	board.balance.lean = 0.6
	board.balance.lean_dir = 0.0
	for i: int in 30:
		board.balance.lean = 0.6
		board.balance.lean_dir = 0.0
		await get_tree().physics_frame
	assert_gt(camera._lean, 0.05, "The view rolls with the lean")
	var up: Vector3 = camera.global_basis.y
	assert_gt(absf(up.x) + absf(up.z), 0.03, "so the camera's up is off vertical")
