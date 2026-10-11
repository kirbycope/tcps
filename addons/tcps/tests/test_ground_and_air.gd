extends GutTest
## Purpose: the ground and the air follow THUG's rules. A turn keeps the speed and puts all of it along the
## facing, so the board never slides; a kick is a steady acceleration to a cap and the wind is the only friction;
## the ollie is charged by the hold; a wall is bounced off with the speed scaled by the angle, never ground along;
## a manual is two taps and ends in a bail when the meter runs out.

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
	assert_true(player.is_riding, "The Player is on the board")


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint"]:
		Input.action_release(action)


## Puts the rider on the open concrete facing [param heading] at [param speed], and waits for the ground under
## them: a warp lands a hair above it, and the board is in the air until the body touches down.
func _place(at: Vector3, heading: Vector3, speed: float) -> void:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(heading.x, heading.z)), Vector3(at.x, 0.02, at.z)))
	player.velocity = heading * speed
	var frames: int = 0
	while not (player.is_on_floor() and board.state == Skateboard.State.GROUND) and frames < 30:
		player.velocity = Vector3(heading.x * speed, player.velocity.y, heading.z * speed)
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND, "The rider is on the ground to start")
	player.velocity = heading * speed


func _speed() -> float:
	return player.velocity.slide(Vector3.UP).length()


func test_a_kick_is_a_steady_acceleration_to_a_cap_and_coasting_keeps_the_speed() -> void:
	await _place(Vector3(-30.0, 0.1, 30.0), Vector3.RIGHT, 0.0)
	Input.action_press(&"move_up")
	await wait_physics_frames(30)
	var after_half_a_second: float = _speed()
	assert_between(after_half_a_second, 6.0, 9.5, "Half a second of THUG's kick is about eight metres a second, not top speed")
	await wait_physics_frames(120)
	assert_almost_eq(_speed(), Skateboard.KICK_MAX_SPEED, 0.6, "Two and a half seconds in, the kick has reached its cap")
	Input.action_release(&"move_up")
	var before: float = _speed()
	await wait_physics_frames(120)
	assert_gt(_speed(), before * 0.55, "Two seconds of coasting loses about a third to the wind and nothing to the wheels")


func test_a_turn_keeps_the_speed_and_puts_it_all_along_the_facing() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 10.0)
	Input.action_press(&"move_up")
	Input.action_press(&"move_left")
	await wait_physics_frames(45)
	assert_gt(_speed(), 9.0, "Three quarters of a second of turning at speed keeps the speed (the kick against the wind)")
	var facing: Vector3 = player.orientation.basis.z.slide(Vector3.UP).normalized()
	assert_almost_eq(player.velocity.slide(Vector3.UP).normalized().dot(facing), 1.0, 0.01, "and the velocity is along the facing: no sliding")
	var turned: float = Vector3.RIGHT.signed_angle_to(facing, Vector3.UP)
	assert_almost_eq(turned, Skateboard.TURN_RATE * 0.75, 0.25, "The turn is the constant rate, whatever the speed")


func test_the_ollie_is_charged_by_the_hold() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board._ollie(0.0)
	var tap_pop: float = player.velocity.y
	assert_almost_eq(tap_pop, Skateboard.OLLIE_MIN_SPEED, 0.01, "A tap pops the least")
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board._ollie(Skateboard.MAX_TENSE_TIME * 0.5)
	assert_almost_eq(player.velocity.y, lerpf(Skateboard.OLLIE_MIN_SPEED, Skateboard.OLLIE_MAX_SPEED, 0.5), 0.01, "Half the hold pops half way")
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board._ollie(Skateboard.MAX_TENSE_TIME * 3.0)
	assert_almost_eq(player.velocity.y, Skateboard.OLLIE_MAX_SPEED, 0.01, "and holding longer than the charge adds nothing")


func test_a_wall_head_on_stops_the_board_instead_of_pinning_it() -> void:
	# The park's wall is a 3 m slab at x = 25 (its west face at x = 24.8), running along z
	await _place(Vector3(20.0, 0.1, 25.0), Vector3.RIGHT, 6.0)
	Input.action_press(&"move_up")
	await wait_physics_frames(60)
	assert_lt(_speed(), 1.5, "A head-on hit takes the speed away")
	assert_lt(player.global_position.x, 24.8, "and the rider is outside the wall")


func test_a_glancing_wall_turns_the_board_along_it_and_keeps_most_of_the_speed() -> void:
	# Hit the wall at about 20 degrees, travelling mostly along it (+z) and into it (+x)
	var heading: Vector3 = Vector3(sin(deg_to_rad(20.0)), 0.0, cos(deg_to_rad(20.0)))
	await _place(Vector3(23.0, 0.1, 21.0), heading, 8.0)
	await wait_physics_frames(60)
	assert_gt(_speed(), 6.0, "A glance keeps most of the speed")
	assert_lt(player.velocity.x, 0.5, "and runs along the wall rather than into it")
	assert_lt(player.global_position.x, 24.8, "outside it")


func test_two_taps_start_a_manual_and_the_meter_ends_it() -> void:
	seed(3)
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	var events: Array[String] = []
	board.trick_started.connect(func(kind: String) -> void: events.append("start " + kind))
	board.trick_ended.connect(func(kind: String, bailed: bool) -> void: events.append("end " + kind + (" bail" if bailed else "")))
	var up: InputEventAction = InputEventAction.new()
	up.action = &"move_up"
	up.pressed = true
	var down: InputEventAction = InputEventAction.new()
	down.action = &"move_down"
	down.pressed = true
	board.ride_input(player, up)
	board.ride_input(player, down)
	assert_eq(events, ["start manual"], "Up then Down within the window is a manual")
	assert_not_null(board.balance, "with the meter running")
	assert_eq(board.trick, "manual")
	var ticks: int = 0
	while board.balance != null and ticks < 900:
		await get_tree().physics_frame
		ticks += 1
	assert_eq(events, ["start manual", "end manual bail"], "and with nobody balancing it ends in a bail")
	assert_lt(_speed(), 8.0 * Skateboard.BAIL_SPEED_SCALE + 0.5, "which takes the speed")
	assert_gt(board._bail_timer, 0.0, "and the controls for a moment")


func test_down_then_up_is_a_nose_manual() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	var down: InputEventAction = InputEventAction.new()
	down.action = &"move_down"
	down.pressed = true
	var up: InputEventAction = InputEventAction.new()
	up.action = &"move_up"
	up.pressed = true
	board.ride_input(player, down)
	board.ride_input(player, up)
	assert_eq(board.trick, "nose_manual")


func test_a_tap_in_the_air_does_not_spin_but_a_hold_does() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board._ollie()
	var facing_before: Vector3 = player.orientation.basis.z
	Input.action_press(&"move_left")
	await wait_physics_frames(3)
	Input.action_release(&"move_left")
	await wait_physics_frames(2)
	assert_almost_eq(player.orientation.basis.z.angle_to(facing_before), 0.0, 0.02, "Three frames of Left in the air is a tap: no spin")
	Input.action_press(&"move_left")
	await wait_physics_frames(24)
	Input.action_release(&"move_left")
	assert_gt(player.orientation.basis.z.angle_to(facing_before), deg_to_rad(30.0), "Held, it spins")


func _event(action: StringName, pressed: bool = true) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func test_up_up_then_the_pop_is_a_boneless_and_up_then_the_pop_a_no_comply() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board.ride_input(player, _event(&"move_up"))
	board.ride_input(player, _event(&"move_up"))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_almost_eq(player.velocity.y, lerpf(Skateboard.BONELESS_MAX_SPEED_STAT.x, Skateboard.BONELESS_MAX_SPEED_STAT.y, 0.5) * Skateboard.INCH, 0.01, "Two Up taps then the pop is a boneless: a higher pop (Physics_Boneless_Jump_Speed_Stat)")
	assert_eq(board.tricks.names(), ["Boneless"], "worth THUG's 250 in the combo")
	assert_eq(board.tricks.combo_points(), 250)
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 240:
		await get_tree().physics_frame
		frames += 1
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board.tricks = SkateTricks.new()
	board.ride_input(player, _event(&"move_up"))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_almost_eq(player.velocity.y, Skateboard.OLLIE_MAX_SPEED, 0.01, "One Up then the pop is a no comply, at the ollie's own height")
	assert_eq(board.tricks.names(), ["No Comply"])
	frames = 0
	while board.state != Skateboard.State.GROUND and frames < 240:
		await get_tree().physics_frame
		frames += 1
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	await wait_physics_frames(2)
	board.tricks = SkateTricks.new()
	board.ride_input(player, _event(&"move_up"))
	board.ride_input(player, _event(&"move_up"))
	board._clock += Skateboard.BONELESS_WINDOW + 0.1
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_eq(board.tricks.names(), [], "Taps older than the window are nothing: a plain ollie")
	assert_almost_eq(player.velocity.y, Skateboard.OLLIE_MAX_SPEED, 0.01)


func test_slow_on_a_steep_slope_the_board_turns_downhill_and_will_not_brake() -> void:
	# A face 75 degrees from flat, rising toward -x; the rider faces along it (+z), nearly stopped, with Down held
	var normal: Vector3 = Vector3(sin(deg_to_rad(75.0)), cos(deg_to_rad(75.0)), 0.0)
	player.orientation.basis = Basis.IDENTITY
	player.velocity = Vector3(0.0, 0.0, 0.5)
	assert_almost_eq(player.orientation.basis.z.angle_to(Vector3.RIGHT), PI * 0.5, 0.001, "To start the facing is square across the fall line, which runs downhill to +x")
	for i: int in 12:
		board._roll(Vector2(0.0, -1.0), false, normal, 1.0 / 60.0)
	assert_lt(player.orientation.basis.z.angle_to(Vector3.RIGHT), PI * 0.5 - 0.5, "A fifth of a second on the facing has swung toward downhill at Skater_Slow_Turn_on_slopes")
	assert_almost_eq(player.orientation.basis.z.y, 0.0, 0.001, "as a yaw: the facing stays level")
	assert_gt(player.velocity.length(), 0.5, "and Down did not brake: the board slides off the slope")
	player.orientation.basis = Basis(Vector3.UP, atan2(-1.0, 0.0)) # facing up the face, and climbing it
	player.velocity = Vector3(-1.6, 6.0, 0.0)
	for i: int in 5:
		board._roll(Vector2.ZERO, false, normal, 1.0 / 60.0)
	assert_almost_eq(player.orientation.basis.z.angle_to(Vector3.RIGHT), PI, 0.001, "A climb is left alone: the turn cannot bend a launch sideways")
	assert_gt(player.velocity.y, 3.0, "and the board is still climbing")
	player.orientation.basis = Basis.IDENTITY
	player.velocity = Vector3(0.0, 0.0, 0.5)
	for i: int in 12:
		board._roll(Vector2(0.0, -1.0), false, Vector3.UP, 1.0 / 60.0)
	assert_almost_eq(player.orientation.basis.z, Vector3.BACK, Vector3.ONE * 0.001, "On the flat the facing is left alone")
	assert_lt(player.velocity.length(), 0.5, "and Down brakes")


func test_grind_held_square_into_a_wall_pushes_the_board_back_off_it() -> void:
	await _place(Vector3(20.0, 0.1, 25.0), Vector3.RIGHT, 6.0)
	Input.action_press(&"action")
	await wait_physics_frames(60)
	Input.action_release(&"action")
	assert_lt(player.velocity.x, -1.0, "The wallpush sends the board back the way it came")
	assert_gt(_speed(), Skateboard.WALLPUSH_MIN_EXIT_SPEED - 0.1, "at no less than Physics_Wallpush_Min_Exit_Speed")
	assert_lt(player.global_position.x, 24.8, "outside the wall")


func test_a_manual_pushed_off_a_wall_comes_back_as_the_other_manual() -> void:
	seed(3)
	await _place(Vector3(23.0, 0.1, 25.0), Vector3.RIGHT, 6.0)
	board._start_trick("manual")
	assert_eq(board.trick, "manual")
	Input.action_press(&"action")
	var frames: int = 0
	while board.trick == "manual" and frames < 90:
		await get_tree().physics_frame
		frames += 1
	Input.action_release(&"action")
	assert_eq(board.trick, "nose_manual", "Off the wall the manual carries on as a nose manual (Manual_Wallpush's ToNoseManual)")
	assert_eq(board.tricks.names(), ["Manual", "Wallpush", "Nose Manual"], "with the push in the combo")
	assert_lt(player.velocity.x, 0.0, "rolling back the way it came")


func test_the_speed_caps_are_lifted_after_a_fast_transfer_and_settle_back() -> void:
	var soft_cap: float = board._stat(Skateboard.MAX_SPEED_STAT)
	board._begin_transfer_override(soft_cap * 1.2)
	assert_eq(board._transfer_override, 1.0, "A transfer ending under 1.25 times the soft cap lifts nothing")
	board._begin_transfer_override(soft_cap * 2.0)
	assert_almost_eq(board._transfer_override, Skateboard.TRANSFER_OVERRIDE_MAX, 0.0001, "One ending at twice it lifts the caps to Physics_Transfer_Speed_Limit_Override_Max")
	player.orientation.basis = Basis.IDENTITY
	player.velocity = Vector3(0.0, 0.0, soft_cap * 1.7)
	board._roll(Vector2.ZERO, false, Vector3.UP, 1.0 / 60.0)
	assert_gt(player.velocity.slide(Vector3.UP).length(), board._stat(Skateboard.MAX_MAX_SPEED_STAT), "and the board keeps a speed over the hard cap")
	var ticks: int = 0
	while board._transfer_override > 1.0 and ticks < 600:
		player.velocity = Vector3(0.0, 0.0, soft_cap * 1.7)
		board._roll(Vector2.ZERO, false, Vector3.UP, 1.0 / 60.0)
		ticks += 1
	assert_almost_eq(ticks / 60.0, (Skateboard.TRANSFER_OVERRIDE_MAX - 1.0) / Skateboard.TRANSFER_OVERRIDE_DROP_RATE, 0.1, "The lift drops by the drop rate each second on the ground")
	player.velocity = Vector3(0.0, 0.0, soft_cap * 1.7)
	board._roll(Vector2.ZERO, false, Vector3.UP, 1.0 / 60.0)
	assert_lte(player.velocity.slide(Vector3.UP).length(), board._stat(Skateboard.MAX_MAX_SPEED_STAT) + 0.001, "and then the hard cap stands again")
	board._begin_transfer_override(soft_cap * 2.0)
	player.velocity = Vector3(0.0, 0.0, soft_cap * 0.5)
	board._roll(Vector2.ZERO, false, Vector3.UP, 1.0 / 60.0)
	assert_eq(board._transfer_override, 1.0, "Slowing under the cap ends the lift at once: it never raises a speed")
