extends GutTest
## Purpose: the rest of THUG's vert and wall repertoire. Grind rising past a coping is a lip trick that stops the
## skater on the coping and drops them back in on the pop; Grind on a ridable wall in the air is a wall ride that
## bends toward the ground; Ollie at a wall in the air is a wallplant that throws the skater back off it; a spine
## button rising in vert air carries the skater over a spine to its far face; a spine button in plain air drops
## them into a vert face ahead.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/demo/demo.tscn")

var park: Node3D
var player: Player
var board: Skateboard


func before_each() -> void:
	park = PARK_SCENE.instantiate()
	(park.get_node("MountTimer") as Timer).autostart = false
	add_child_autofree(park)
	player = park.get_node("Player")
	board = park.get_node("Skateboard")
	player.mount(board)
	await wait_physics_frames(3)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint", &"focus"]:
		Input.action_release(action)


## Puts the rider in the air at [param at] heading [param heading] with [param velocity].
func _fly_at(at: Vector3, heading: Vector3, velocity: Vector3) -> void:
	player.warp_to(Transform3D(Basis.looking_at(-heading, Vector3.UP), at))
	player.velocity = velocity
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._air_time = 0.3
	board._old_position = at
	board.vert_out = Vector3.ZERO
	board.vert_normal = Vector3.ZERO


## Puts the rider in vert air on the quarter pipe's face (at x = -18, facing -x, into the pipe is +x), rising.
func _vert_air_on_the_quarter_pipe(height: float, rise: float) -> void:
	_fly_at(Vector3(-18.0 + Skateboard.VERT_PUSH_OUT, height, 4.0), Vector3.LEFT, Vector3(0.0, rise, 0.0))
	board.vert_normal = Vector3.RIGHT
	board.vert_out = Vector3.LEFT
	board.last_floor_normal = Vector3.RIGHT
	board._vert_point = player.global_position


func test_the_park_has_copings_a_spine_a_bank_and_a_ridable_wall() -> void:
	for path: String in ["HalfPipe/LeftCopingRail", "HalfPipe/RightCopingRail", "QuarterPipeCoping", "SpineNearCoping", "SpineFarCoping"]:
		assert_true(park.get_node(path) is Rail, path + " is a rail")
	assert_almost_eq((park.get_node("QuarterPipeCoping") as Rail).point_at(12.0), Vector3(-18.0, 3.3, 4.0), Vector3.ONE * 0.01, "The quarter pipe's coping is along its lip (16 m of it, from z = -8)")
	assert_true(park.get_node("Spine").is_in_group("WOOD"), "The spine is wood")
	assert_true(park.get_node("Bank").is_in_group("WOOD"), "and so is the bank up to the quarter pipe's deck")
	assert_true(park.get_node("Wall").is_in_group("wallride"), "The wall can be ridden")


func test_time_to_reach_height_is_the_way_down_through_it() -> void:
	var t: float = Skateboard.time_to_reach_height(0.0, 0.0, 10.0)
	assert_almost_eq(t, 2.0 * 10.0 / Skateboard.AIR_GRAVITY, 0.001, "Back to the same height takes twice the time to the top")
	assert_lt(Skateboard.time_to_reach_height(100.0, 0.0, 1.0), 0.0, "A height never reached is -1")
	var down: float = Skateboard.time_to_reach_height(-5.0, 0.0, 0.0)
	assert_almost_eq(0.5 * Skateboard.AIR_GRAVITY * down * down, 5.0, 0.001, "Falling five metres from rest takes the free-fall time")


func test_grind_rising_past_the_coping_is_a_lip_trick_that_stops_the_skater() -> void:
	_vert_air_on_the_quarter_pipe(3.25, 4.0)
	Input.action_press(&"action")
	await wait_physics_frames(3)
	assert_eq(board.state, Skateboard.State.LIP, "Rising past the coping with Grind held is a lip")
	assert_eq(board.trick, "lip", "with the lip's balance running")
	assert_eq(board.tricks.names(), ["Nose Stall"], "and the stall in the combo (THUG's DefaultLipTrick with nothing held)")
	assert_almost_eq(player.velocity, Vector3.ZERO, Vector3.ONE * 0.001, "The skater has stopped dead")
	assert_almost_eq(player.global_position.y, 3.3, 0.05, "on the coping")
	var stopped: Vector3 = player.global_position
	await wait_physics_frames(10)
	assert_almost_eq(player.global_position, stopped, Vector3.ONE * 0.001, "and stays there")
	Input.action_release(&"action")
	board._ollie(0.1)
	assert_eq(board.state, Skateboard.State.AIR, "The pop leaves the lip")
	assert_almost_eq(player.global_position.x, -18.0 + Skateboard.VERT_PUSH_OUT, 0.01, "back where the skater was on the wall")
	assert_eq(board.vert_normal, Vector3.RIGHT, "still vert, to drop back in")
	assert_gt(player.velocity.y, 0.0, "with the pop")
	assert_null(board.balance, "and the balance over")


func test_the_lips_needle_off_the_meter_is_a_bail_back_into_the_pipe() -> void:
	_vert_air_on_the_quarter_pipe(3.25, 4.0)
	Input.action_press(&"action")
	await wait_physics_frames(3)
	assert_eq(board.state, Skateboard.State.LIP)
	board.balance.lean = 1.0
	await wait_physics_frames(2)
	assert_ne(board.state, Skateboard.State.LIP, "Off the end of the meter the skater falls back in (onto the wall, right below)")
	assert_gt(board._bail_timer, 0.0, "as a bail")
	assert_true(board.tricks.combo.is_empty(), "and the combo is gone")


func test_up_held_on_the_pop_jumps_out_over_the_deck() -> void:
	_vert_air_on_the_quarter_pipe(3.25, 4.0)
	Input.action_press(&"action")
	await wait_physics_frames(3)
	assert_eq(board.state, Skateboard.State.LIP)
	Input.action_release(&"action")
	player.player_input.motion = Vector2(0.0, 1.0)
	board._ollie(0.1)
	assert_lt(player.global_position.x, -18.0, "The skater starts over the deck")
	assert_almost_eq(player.velocity.x, -Skateboard.LIP_SIDE_JUMP_SPEED, 0.01, "heading onto it at the lip jump speed")
	assert_eq(board.vert_normal, Vector3.ZERO, "as plain air")


func test_grind_on_the_wall_in_the_air_is_a_wall_ride_that_bends_toward_the_ground() -> void:
	# The wall's west face is at x = 24.8, running along z from 19 to 31; come at it climbing, mostly along it
	var heading: Vector3 = Vector3(0.5, 0.0, 0.8).normalized()
	_fly_at(Vector3(24.3, 1.2, 21.0), heading, Vector3(3.0, 4.0, 5.0)) # the wall is 3 m tall; start low enough not to clear it
	Input.action_press(&"action")
	var frames: int = 0
	while board.state != Skateboard.State.WALL and frames < 20:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.WALL, "The wall with Grind held is a wall ride")
	assert_almost_eq(board.wall_normal, Vector3.LEFT, Vector3.ONE * 0.01, "on the wall's face")
	assert_almost_eq(player.velocity.x, 0.0, 0.05, "The velocity is in the wall's plane")
	assert_eq(board.tricks.names(), ["Wallride"], "and the ride is in the combo")
	var climb: float = player.velocity.y
	await wait_physics_frames(15)
	assert_eq(board.state, Skateboard.State.WALL, "still riding a quarter second on")
	assert_lt(player.velocity.y, climb - 3.0, "The wall's gravity and the bend pull the ride down")
	assert_almost_eq(player.velocity.x, 0.0, 0.05, "still in the wall's plane")


func test_the_wall_ride_needs_speed_along_the_wall_and_a_ridable_wall() -> void:
	_fly_at(Vector3(24.3, 1.2, 22.0), Vector3.RIGHT, Vector3(3.0, 4.0, 0.5))
	Input.action_press(&"action")
	await wait_physics_frames(20)
	assert_ne(board.state, Skateboard.State.WALL, "Square into the wall with no speed along it is a bonk, not a ride")


func test_ollie_pressed_square_into_the_wall_is_a_wallplant() -> void:
	_fly_at(Vector3(23.8, 1.5, 25.0), Vector3.RIGHT, Vector3(8.0, 2.0, 0.0))
	Input.parse_input_event(_event(&"jump"))
	var frames: int = 0
	while board._wallplant_timer <= 0.0 and frames < 20:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.tricks.names(), ["Wallplant"], "Ollie at the wall is a wallplant")
	assert_gt(board._wallplant_timer, 0.0, "frozen on the wall for a moment")
	assert_almost_eq(player.velocity, Vector3.ZERO, Vector3.ONE * 0.001)
	frames = 0
	while board._wallplant_timer > 0.0 and frames < 20:
		await get_tree().physics_frame
		frames += 1
	assert_lt(player.velocity.x, -Skateboard.WALLPLANT_MIN_EXIT_SPEED + 0.01, "then thrown back the way they came")
	assert_gt(player.velocity.y, Skateboard.WALLPLANT_VERTICAL_EXIT_SPEED - 1.0, "and up at the plant's climb")
	assert_eq(board.state, Skateboard.State.AIR)


func test_a_spine_button_rising_on_the_spine_transfers_to_the_far_face() -> void:
	# The spine's near face is at x = 17 (up it is -x), its far face at x = 16.7; the rider is on the near face
	_fly_at(Vector3(17.0 + Skateboard.VERT_PUSH_OUT, 3.2, -4.0), Vector3.LEFT, Vector3(0.0, 6.0, 0.0))
	board.vert_normal = Vector3.RIGHT
	board.vert_out = Vector3.LEFT
	board.last_floor_normal = Vector3.RIGHT
	board._vert_point = player.global_position
	Input.action_press(&"focus")
	var frames: int = 0
	while not board._transferring and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_true(board._transferring, "Above the deck the transfer takes over")
	assert_eq(board.tricks.names(), ["Spine Transfer"], "and is in the combo")
	assert_almost_eq(board._transfer_normal, Vector3.LEFT, Vector3.ONE * 0.01, "aimed at the far face")
	Input.action_release(&"focus")
	frames = 0
	while board.state != Skateboard.State.GROUND and frames < 240:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND, "and the skater lands")
	assert_lt(player.global_position.x, 16.8, "on the far side of the spine")


func test_a_spine_button_in_plain_air_off_the_deck_is_an_acid_drop_into_the_quarter_pipe() -> void:
	# Over the quarter pipe's deck heading for its lip at x = -18, the pipe beyond it
	_fly_at(Vector3(-18.6, 3.6, 4.0), Vector3.RIGHT, Vector3(4.0, 1.0, 0.0))
	board._left_ground_at = board._now()
	board._last_jump_at = -10.0
	Input.action_press(&"focus")
	var frames: int = 0
	while not board._transferring and frames < 30:
		await get_tree().physics_frame
		frames += 1
	assert_true(board._transferring, "The drop takes the skater")
	assert_eq(board.tricks.names(), ["Acid Drop"])
	assert_almost_eq(board.vert_normal, Vector3.RIGHT, Vector3.ONE * 0.01, "into the quarter pipe's face")
	assert_gte(player.velocity.y, Skateboard.ACID_DROP_POP_SPEED - Skateboard.AIR_GRAVITY / 60.0 - 0.01, "with the small pop a drop off an edge gets (less one tick of gravity)")
	Input.action_release(&"focus")
	frames = 0
	while board.state != Skateboard.State.GROUND and frames < 240:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND, "and lands")
	assert_gt(player.global_position.x, -18.0, "on the face, inside the pipe")
	assert_lt(player.global_position.y, 3.3, "below the lip")


func test_breaking_vert_wants_up_held_a_while_not_a_twitch() -> void:
	board.last_floor_normal = Vector3.RIGHT
	player.velocity = Vector3(0.0, 8.0, 0.0)
	board._clock = 10.0 # well into the ride, so a press before the tick is still on the clock
	board._up_since = board._clock
	board._launch(Vector3.UP)
	assert_eq(board.vert_normal, Vector3.RIGHT, "Up down for an instant at take-off is still a vert air")
	board.vert_normal = Vector3.ZERO
	board.vert_out = Vector3.ZERO
	board._up_since = board._clock - Skateboard.VERT_PUSH_TIME - 0.01
	board._launch(Vector3.UP)
	assert_eq(board.vert_normal, Vector3.ZERO, "held for Skater_vert_push_time it breaks vert")
	assert_lt(player.velocity.x, 0.0, "and the skater goes over the deck")


func test_through_a_lip_trick_the_camera_drops_into_the_pipe_and_looks_up() -> void:
	_vert_air_on_the_quarter_pipe(3.25, 4.0)
	Input.action_press(&"action")
	await wait_physics_frames(3)
	assert_eq(board.state, Skateboard.State.LIP)
	await wait_physics_frames(30) # half a second in; a stall left unbalanced lasts well under a second
	assert_eq(board.state, Skateboard.State.LIP, "still on the coping")
	var camera: Camera3D = board.camera
	assert_lt(camera.global_position.y, 3.3, "The camera is below the coping")
	assert_gt(camera.global_position.x, -18.0, "inside the pipe")
	assert_gt((-camera.global_basis.z).y, 0.3, "looking up at the skater")
	assert_true(board._ray(camera.global_position, camera.global_position + Vector3.UP * 0.01).is_empty(), "and in the open, not in the ramp")


func _event(action: StringName, pressed: bool = true) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event
