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
	assert_eq(SkateTricks.named(SkateTricks.FLIPS, "right"), ["Heelflip", 100], "THUG's created skater's slots (CustomTricks_default)")
	assert_eq(SkateTricks.named(SkateTricks.FLIPS, "up_right"), ["Inward Heelflip", 350], "with the diagonals")
	assert_eq(SkateTricks.named(SkateTricks.GRABS, "down"), ["Tailgrab", 300], "THUG's own points, from airtricks.q")
	assert_eq(SkateTricks.named(SkateTricks.GRABS, "up_right"), ["Madonna", 750])
	assert_eq(SkateTricks.named(SkateTricks.GRINDS, "up"), ["Nosegrind", 100])
	assert_eq(SkateTricks.named_grind("down_left", false), ["Smith", 125], "GrindTrickList by direction")
	assert_eq(SkateTricks.named_grind("left", true), ["Boardslide", 200], "a rail taken across the travel is a slide")
	assert_eq(SkateTricks.named_grind("up", true), ["Nosegrind", 100], "except where THUG has no slide for the direction")
	assert_eq(SkateTricks.named(SkateTricks.LIPS, ""), ["Nose Stall", 300], "DefaultLipTrick")
	assert_eq(SkateTricks.named(SkateTricks.LIPS, "up_right"), ["The Switcheroo", 600], "HawkLip")
	assert_eq(SkateTricks.named(SkateTricks.GRINDS, "sideways"), ["50-50", 100], "an unknown direction is the plain trick")
	assert_eq(SkateTricks.direction_of(Vector2(0.0, 1.0)), "up")
	assert_eq(SkateTricks.direction_of(Vector2(-1.0, 0.0)), "left")
	assert_eq(SkateTricks.direction_of(Vector2(1.0, -1.0)), "down_right", "both held is the diagonal")
	assert_eq(SkateTricks.direction_of(Vector2.ZERO), "")
	assert_eq(SkateTricks.extra_for("Kickflip"), ["Double Kickflip", 500], "ExtraTricks")
	assert_eq(SkateTricks.extra_for("Double Kickflip"), ["Triple Kickflip", 1000])
	assert_eq(SkateTricks.extra_for("Triple Kickflip"), [], "and no further")
	assert_eq(SkateTricks.double_tap("flip", ["up", "up"]), ["Sal Flip", 900], "Air_U_U_Square")
	assert_eq(SkateTricks.double_tap("grind", ["down", "down"]), ["Bluntslide", 250])
	assert_eq(SkateTricks.double_tap("flip", ["up", "down"]), [])


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
	assert_eq(tricks.add_spin(170.0, true), "FS 180", "A left spin is frontside")
	tricks.add("Manual", 100)
	assert_eq(tricks.names(), ["Kickflip", "Manual"])
	assert_eq(tricks.combo_points(), 150 + 100, "The spin multiplies the trick it is on: a 180 is one and a half times (THUG's SPIN_MULT_VALUES)")
	assert_eq(tricks.combo_total(), 250 * 2, "Base points times the number of tricks")
	assert_eq(tricks.total_text(), "250 x 2")
	assert_eq(tricks.combo_text(), "FS 180 Kickflip + Manual")
	assert_eq(tricks.land_clean(), 500)
	assert_eq(tricks.score, 500)
	assert_true(tricks.combo.is_empty())
	tricks.add("Melon", 300)
	tricks.bail()
	assert_eq(tricks.score, 500, "A bail loses the combo, not the score")
	assert_eq(SkateTricks._with_commas(1234567), "1,234,567")
	assert_eq(tricks.add_spin(-360.0), "BS 360", "A right spin is backside")
	assert_eq(tricks.names(), ["Ollie"], "and a spin with no trick in the air is on the ollie (THUG's 75 points)")
	assert_eq(tricks.combo_points(), 150)
	assert_eq(tricks.add_spin(180.0), "BS 180", "An odd half turn on an ollie lands fakie, so its side is swapped")


func test_the_button_again_mid_flip_is_the_extra_and_the_combo_takes_the_new_name() -> void:
	var tricks: SkateTricks = SkateTricks.new()
	tricks.add("Kickflip", 100)
	tricks.upgrade_last("Double Kickflip", 500)
	assert_eq(tricks.names(), ["Double Kickflip"], "The extra replaces the trick, it is not a second one")
	assert_eq(tricks.combo_points(), 500)
	tricks.upgrade_last("Triple Kickflip", 1000)
	assert_eq(tricks.combo_points(), 1000)
	tricks.land_clean()
	tricks.add("Kickflip", 100)
	assert_eq(tricks.combo_points(), 100, "A kickflip that became a triple does not count as a kickflip done")


func test_in_the_air_the_flip_button_again_doubles_the_flip_and_a_double_tap_names_the_flip() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Kickflip")
	await wait_physics_frames(6)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Double Kickflip", "The button again mid-flip is the extra")
	assert_eq(board.tricks.names(), ["Double Kickflip"])
	assert_lt(board._air_trick_time, 0.05, "and the flip turns again from the start")
	await wait_physics_frames(6)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Triple Kickflip")
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Triple Kickflip", "and there is no further extra")
	# A new air (once the bail a triple needs more air than this has is over): Up, Up, Flip is the Sal Flip
	var frames: int = 0
	while (board.state != Skateboard.State.GROUND or board._bail_timer > 0.0) and frames < 240:
		await get_tree().physics_frame
		frames += 1
	await wait_physics_frames(2)
	board._clock += 10.0
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	board.ride_input(player, _event(&"move_up"))
	board.ride_input(player, _event(&"move_up"))
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Sal Flip", "Up, Up, Flip is the double-tap trick")


func test_a_trick_done_again_in_the_run_is_worth_less_each_time() -> void:
	var tricks: SkateTricks = SkateTricks.new()
	tricks.add("Kickflip", 100)
	tricks.add("Kickflip", 100)
	assert_eq(tricks.combo_points(), 100 + 75, "The second in a combo is three quarters (THUG's DEPREC_VALUES)")
	tricks.land_clean()
	tricks.add("Kickflip", 100)
	assert_eq(tricks.combo_points(), 50, "and the third in the run is half")
	tricks.bail()
	tricks.add("Kickflip", 100)
	assert_eq(tricks.combo_points(), 50, "A bailed combo's uses do not count")


func test_the_special_meter_fills_with_the_combo_lights_full_and_drains() -> void:
	var tricks: SkateTricks = SkateTricks.new()
	tricks.add("Kickflip", 100)
	assert_almost_eq(tricks.special, 100.0, 0.01, "The meter is fed as the combo grows, before the landing")
	tricks.add("Manual", 100)
	assert_almost_eq(tricks.special, 400.0, 0.01, "by what the combo's worth grew")
	assert_false(tricks.special_lit)
	assert_almost_eq(tricks.stat(), SkateTricks.STAT, 0.001)
	tricks.update(2.0)
	assert_almost_eq(tricks.special, 300.0, 0.01, "It drains fifty points a second")
	tricks.add("McTwist", 5000)
	assert_true(tricks.special_lit, "Past three thousand it lights")
	assert_almost_eq(tricks.special, SkateTricks.SPECIAL_FULL, 0.01, "and holds at the top")
	assert_almost_eq(tricks.stat(), SkateTricks.SPECIAL_STAT, 0.001, "with three more on every stat")
	tricks.update(1.0)
	assert_almost_eq(tricks.special, 2800.0, 0.01, "Lit, it drains two hundred a second")
	assert_true(tricks.special_lit, "and stays lit while any is left")
	tricks.update(20.0)
	assert_false(tricks.special_lit, "Empty, it goes out")
	tricks.add("Kickflip", 100)
	tricks.add("McTwist", 5000)
	assert_true(tricks.special_lit)
	tricks.bail()
	assert_almost_eq(tricks.special, 0.0, 0.01, "A bail empties it (THUG's Score::Bail)")
	assert_false(tricks.special_lit)


func test_two_taps_and_a_button_are_a_special_trick_only_with_the_meter_lit() -> void:
	var tricks: SkateTricks = SkateTricks.new()
	assert_eq(tricks.special_trick("flip", ["left", "right"]), [], "Unlit, the taps mean nothing")
	tricks.special_lit = true
	assert_eq(tricks.special_trick("flip", ["left", "right"]), ["Kickflip Underflip", 1000], "Lit, Left Right Flip is the created skater's special flip")
	assert_eq(tricks.special_trick("grab", ["right", "down"]), ["McTwist", 5000])
	assert_eq(tricks.special_trick("grind", ["right", "down"]), ["Tailblock Slide", 500])
	assert_eq(tricks.special_trick("flip", ["right", "left"]), [], "in that order")
	assert_eq(tricks.special_trick("flip", ["right"]), [])


func test_the_board_reads_the_taps_and_the_meter_lifts_the_stats() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._clock = 10.0
	board.ride_input(player, _event(&"move_left"))
	board.ride_input(player, _event(&"move_right"))
	assert_eq(board._recent_taps(), ["left", "right"], "The last two taps, oldest first")
	board._clock += SkateTricks.SPECIAL_WINDOW + 0.1
	assert_eq(board._recent_taps(), [], "and none once the window has passed")
	assert_almost_eq(board._stat(Skateboard.OLLIE_MAX_SPEED_STAT), Skateboard.OLLIE_MAX_SPEED, 0.001, "A stat reads at the middle of its range")
	board.tricks.special_lit = true
	assert_almost_eq(board._stat(Skateboard.OLLIE_MAX_SPEED_STAT), lerpf(414.0, 450.0, 0.8) * Skateboard.INCH, 0.001, "and eight of ten with the meter lit")
	board.ride_input(player, _event(&"move_left"))
	board.ride_input(player, _event(&"move_right"))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Kickflip Underflip", "Left, Right, Flip in the air with the meter lit is the special flip")
	board._refresh_hud()
	assert_true(board.special_label.visible, "and the HUD says SPECIAL")


func test_a_flip_in_the_air_lands_clean_once_it_is_done_and_banks() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	var banked: Array[int] = []
	board.combo_banked.connect(func(points: int) -> void: banked.append(points))
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	assert_eq(board.state, Skateboard.State.AIR)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.air_trick, "Kickflip", "Flip with nothing held is a kickflip")
	assert_eq(board.tricks.names(), ["Kickflip"])
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


func test_a_grab_lasts_while_held() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	await wait_physics_frames(2)
	Input.action_press(&"move_down")
	await get_tree().physics_frame
	Input.action_press(&"sprint")
	board.ride_input(player, _event(&"sprint"))
	assert_eq(board.air_trick, "Tailgrab", "Grab with Down held is a tailgrab")
	assert_eq(board.tricks.combo_points(), 300, "worth THUG's three hundred")
	Input.action_release(&"move_down")
	await wait_physics_frames(15)
	assert_eq(board.air_trick, "Tailgrab", "Held, the grab goes on")
	assert_eq(board.tricks.combo_points(), 300, "and the hold adds nothing, as in THUG")
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
	assert_eq(board.tricks.names(), ["Ollie"], "A spin on a plain ollie is the ollie's")
	assert_string_contains(board.tricks.combo_text(), "180 Ollie", "A left spin of about a half turn lands as a 180")


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
	assert_eq(board.tricks.names(), ["Kickflip", "Manual"])
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
	assert_has(board.tricks.names(), "Nosegrind", "Grind taken with Up held is a nosegrind")


func test_a_rail_taken_across_the_travel_is_a_boardslide() -> void:
	# The ledge's front rail runs along x at z = 15.7; come at it along z, across it, with Grind held
	player.warp_to(Transform3D(Basis(Vector3.UP, 0.0), Vector3(0.0, 0.9, 14.5)))
	player.velocity = Vector3(0.0, 1.0, 5.0)
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._old_position = player.global_position
	Input.action_press(&"action")
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	assert_has(board.tricks.names(), "Boardslide", "Taken across the travel it is a boardslide, THUG's slide entries")


func test_a_revert_in_the_window_keeps_the_combo_after_a_vert_landing() -> void:
	var tricks: SkateTricks = board.tricks
	tricks.add("Melon", 300)
	board._landed_from_vert_at = board._now()
	board._bank_timer = Skateboard.BANK_GRACE
	board.ride_input(player, _event(&"focus"))
	assert_has(tricks.names(), "Revert", "Focus within the window after a vert landing is a revert")
	assert_eq(board._landed_from_vert_at, -1.0, "and only one")
	board.ride_input(player, _event(&"focus"))
	assert_eq(tricks.names().count("Revert"), 1)


func test_the_hud_shows_the_combo_and_the_score() -> void:
	board.tricks.add("Kickflip", 100)
	board.tricks.add_spin(180.0, true)
	board._refresh_hud()
	assert_true(board.trick_line.visible)
	assert_eq(board.trick_line.text, "FS 180 Kickflip")
	assert_eq(board.trick_total.text, "150 x 1")
	assert_true(board.special_bar.visible, "The special meter shows")
	assert_almost_eq(board.special_bar.value, 150.0 / SkateTricks.SPECIAL_FULL, 0.001, "with what the combo has fed it")
	assert_false(board.special_label.visible, "unlit")
	board.tricks.land_clean()
	board._refresh_hud()
	assert_false(board.trick_line.visible, "Nothing in the combo, nothing on the line")
	assert_eq(board.score_label.text, "SCORE 150")


func test_the_board_has_an_animation_for_the_ollie_and_every_flip() -> void:
	assert_true(board.animation_player.has_animation("ollie"))
	for flip: Array in SkateTricks.FLIPS.values():
		var animation: String = Skateboard.animation_name_for(flip[0])
		assert_true(board.animation_player.has_animation(animation), "%s has the animation %s" % [flip[0], animation])
		assert_almost_eq(board.animation_player.get_animation(animation).length, SkateTricks.FLIP_TIME, 0.01, "%s takes as long as the trick" % flip[0])
	assert_eq(board.animation_player.get_animation("kickflip").track_get_path(0), NodePath("Board:rotation"), "The animations turn the pivot the mesh hangs off")
	for name: String in ["varial_kickflip", "varial_heelflip", "inward_heelflip", "sal_flip"]:
		assert_true(board.animation_player.has_animation(name), name + " is animated too")


func test_the_pop_and_a_flip_turn_the_board_and_a_landing_puts_it_back() -> void:
	await _place(Vector3(-20.0, 0.1, 30.0), Vector3.RIGHT, 8.0)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_eq(board.animation_player.current_animation, "ollie", "The pop plays the ollie")
	await wait_physics_frames(3)
	board.ride_input(player, _event(&"attack"))
	assert_eq(board.animation_player.current_animation, "kickflip", "and the flip its own animation")
	await wait_physics_frames(12)
	assert_gt(absf(board.board_pivot.rotation.z), 0.5, "A fifth of a second in, the board has rolled part of the way round")
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		await get_tree().physics_frame
		frames += 1
	await wait_physics_frames(2)
	assert_almost_eq(board.board_pivot.rotation, Vector3.ZERO, Vector3.ONE * 0.01, "On landing the board is level again")
	assert_false(board.animation_player.is_playing())
