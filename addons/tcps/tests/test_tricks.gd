extends GutTest
## Purpose: the trick layer. A button and a direction name a flip or a grab; the spin turned in the air is counted
## to the nearest half turn with THUG's slop; a combo sums its tricks and multiplies by their number; a clean
## landing banks it, a bail loses it, and a manual, a grind or a revert carries it across a landing.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/skate_park.tscn")

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
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint", &"attack", &"focus", &"shoot"]:
		Input.action_release(action)


func _event(action: StringName, pressed: bool = true) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _place(at: Vector3, heading: Vector3, speed: float) -> void:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(heading.x, heading.z)), Vector3(at.x, 0.02, at.z)))
	player.velocity = heading * speed
	var frames: int = 0
	while not (player.is_on_floor() and board.state == Skateboard.State.GROUND) and frames < 30:
		player.velocity = Vector3(heading.x * speed, player.velocity.y, heading.z * speed)
		await get_tree().physics_frame
		frames += 1
	player.velocity = heading * speed


func test_the_tables_name_tricks_by_the_direction_held() -> void:
	assert_eq(SkateTricks.named(SkateTricks.FLIPS, ""), ["Kickflip", 100])
	assert_eq(SkateTricks.named(SkateTricks.FLIPS, "left"), ["Heelflip", 100])
	assert_eq(SkateTricks.named(SkateTricks.GRABS, "down"), ["Tailgrab", 100])
	assert_eq(SkateTricks.named(SkateTricks.GRINDS, "up"), ["Nosegrind", 150])
	assert_eq(SkateTricks.named(SkateTricks.GRINDS, "sideways"), ["50-50", 100], "an unknown direction is the plain trick")
	assert_eq(SkateTricks.direction_of(Vector2(0.0, 1.0)), "up")
	assert_eq(SkateTricks.direction_of(Vector2(-1.0, 0.0)), "left")
	assert_eq(SkateTricks.direction_of(Vector2.ZERO), "")


func test_the_spin_counts_to_the_nearest_half_turn_with_the_slop() -> void:
	assert_eq(SkateTricks.counted_spin(100.0), 0, "A hundred degrees is not yet a 180")
	assert_eq(SkateTricks.counted_spin(125.0), 180, "but within the slop of one it counts")
	assert_eq(SkateTricks.counted_spin(190.0), 180)
	assert_eq(SkateTricks.counted_spin(310.0), 360, "and fifty short of a 360 is a 360")
	assert_eq(SkateTricks.counted_spin(-540.0), 540, "either way round")
	assert_false(SkateTricks.spin_is_sloppy(30.0), "A little off is fine")
	assert_true(SkateTricks.spin_is_sloppy(90.0), "Landing square across the roll is a bail")
	assert_false(SkateTricks.spin_is_sloppy(130.0), "Close enough to the 180 is the 180")


func test_a_combo_sums_and_multiplies_and_a_clean_landing_banks_it() -> void:
	var tricks: SkateTricks = SkateTricks.new()
	tricks.add("Kickflip", 100)
	tricks.add_spin(170.0)
	tricks.add("Manual", 100)
	assert_eq(tricks.combo, ["Kickflip", "FS 180", "Manual"])
	assert_eq(tricks.combo_total(), 300 * 3, "Base points times the number of tricks")
	assert_eq(tricks.total_text(), "300 x 3")
	assert_eq(tricks.combo_text(), "Kickflip + FS 180 + Manual")
	assert_eq(tricks.land_clean(), 900)
	assert_eq(tricks.score, 900)
	assert_true(tricks.combo.is_empty())
	tricks.add("Melon", 100)
	tricks.bail()
	assert_eq(tricks.score, 900, "A bail loses the combo, not the score")
	assert_eq(SkateTricks._with_commas(1234567), "1,234,567")
	assert_eq(tricks.add_spin(-360.0), "BS 360", "A right spin is backside")


func test_a_flip_in_the_air_lands_clean_once_it_is_done_and_banks() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	var banked: Array[int] = []
	board.combo_banked.connect(func(points: int) -> void: banked.append(points))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	assert_eq(board.state, Skateboard.State.AIR)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Kickflip", "Flip with nothing held is a kickflip")
	assert_eq(board.tricks.combo, ["Kickflip"])
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND, "The skater came down")
	assert_gt(board._bail_timer, -1.0)
	await wait_physics_frames(int(Skateboard.BANK_GRACE * 60.0) + 3)
	assert_eq(banked, [100], "A full-hold ollie outlasts a kickflip, so it lands clean and banks a hundred")
	assert_eq(board.tricks.score, 100)
	assert_true(board.tricks.combo.is_empty())


func test_landing_mid_flip_is_a_bail() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	var lost: Array[bool] = []
	board.combo_lost.connect(func() -> void: lost.append(true))
	board._ollie(0.0) # a tap: half a second of air
	await wait_physics_frames(2)
	assert_eq(board.state, Skateboard.State.AIR)
	for i: int in 20:
		await get_tree().physics_frame # a late flip, with less than FLIP_TIME of air left
	board.ride_input(player, _event(&"attack", true))
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		await get_tree().physics_frame
		frames += 1
	assert_eq(lost, [true], "Landing while the board is still flipping is a bail")
	assert_eq(board.tricks.score, 0)
	assert_gt(board._bail_timer, 0.0)


func test_a_grab_lasts_while_held_and_scores_the_hold() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	Input.action_press(&"move_down")
	await get_tree().physics_frame
	Input.action_press(&"sprint")
	board.ride_input(player, _event(&"sprint"))
	assert_eq(board.air_trick, "Tailgrab", "Grab with Down held is a tailgrab")
	Input.action_release(&"move_down")
	var base: int = board.tricks.combo_points
	await wait_physics_frames(15)
	assert_gt(board.tricks.combo_points, base, "Holding the grab keeps adding points")
	Input.action_release(&"sprint")
	await wait_physics_frames(2)
	assert_eq(board.air_trick, "", "Letting go ends the grab")


func test_a_spin_in_the_air_is_counted_on_landing() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	Input.action_press(&"move_left")
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		if board._spin_tally > 150.0:
			Input.action_release(&"move_left") # a 180 and a bit: within the slop of the 180
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND)
	assert_has(board.tricks.combo, "FS 180", "A left spin of about a half turn lands as a frontside 180")


func test_a_manual_out_of_the_landing_keeps_the_combo_and_a_grind_adds_its_name() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	var banked: Array[int] = []
	board.combo_banked.connect(func(points: int) -> void: banked.append(points))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	board.ride_input(player, _event(&"attack"))
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		await get_tree().physics_frame
		frames += 1
	board.ride_input(player, _event(&"move_up"))
	board.ride_input(player, _event(&"move_down"))
	assert_eq(board.trick, "manual", "The manual went in on the landing")
	await wait_physics_frames(int(Skateboard.BANK_GRACE * 60.0) + 3)
	assert_true(banked.is_empty(), "so the combo is not banked yet")
	assert_eq(board.tricks.combo, ["Kickflip", "Manual"])
	assert_eq(board.tricks.combo.size(), 2)
	# Now a grind: throw the rider at the ledge with Up held for a nosegrind
	board._end_trick(false)
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(1.0, 0.0)), Vector3(-3.6, 0.9, 15.7)))
	player.velocity = Vector3(6.0, 1.0, 0.0)
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._old_position = player.global_position
	Input.action_press(&"move_up")
	Input.action_press(&"action")
	frames = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	assert_has(board.tricks.combo, "Nosegrind", "Grind taken with Up held is a nosegrind")


func test_a_revert_in_the_window_keeps_the_combo_after_a_vert_landing() -> void:
	var tricks: SkateTricks = board.tricks
	tricks.add("Melon", 100)
	board._landed_from_vert_at = Skateboard._now()
	board._bank_timer = Skateboard.BANK_GRACE
	board.ride_input(player, _event(&"focus"))
	assert_has(tricks.combo, "Revert", "Focus within the window after a vert landing is a revert")
	assert_eq(board._landed_from_vert_at, -1.0, "and only one")
	board.ride_input(player, _event(&"focus"))
	assert_eq(tricks.combo.count("Revert"), 1)


func test_the_hud_shows_the_combo_and_the_score() -> void:
	board.tricks.add("Kickflip", 100)
	board.tricks.add_spin(180.0)
	board._refresh_hud()
	assert_true(board.trick_line.visible)
	assert_eq(board.trick_line.text, "Kickflip + FS 180")
	assert_eq(board.trick_total.text, "200 x 2")
	board.tricks.land_clean()
	board._refresh_hud()
	assert_false(board.trick_line.visible, "Nothing in the combo, nothing on the line")
	assert_eq(board.score_label.text, "SCORE 400")
