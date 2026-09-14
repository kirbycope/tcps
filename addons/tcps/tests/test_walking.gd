extends GutTest
## Purpose: THUG's skater gets off the board and walks with it. The get-off action leaves the board in the
## skater's hand rather than on the ground, banks the combo and keeps the run's score; on foot the same action gets
## back on, on the ground or in the air; a spine button on foot jumps onto the board, for an acid drop.

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
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint", &"focus", &"whistle"]:
		Input.action_release(action)


func _event(action: StringName, pressed: bool = true) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _get_off() -> void:
	board.ride_input(player, _event(&"whistle"))
	await wait_physics_frames(2)


func test_the_get_off_action_puts_the_board_in_the_skaters_hand() -> void:
	await _get_off()
	assert_false(player.is_riding, "The skater is on foot")
	assert_eq(board.rider_peer, 0, "nobody rides the board")
	assert_eq(board.carrier_peer, player.get_multiplayer_authority(), "the skater carries it")
	assert_eq(board.get_parent(), player.player_model, "so it rides along with their model")
	assert_lt(board.global_position.distance_to(player.global_position), 1.5, "at arm's length")
	assert_gt(board.global_position.y, player.global_position.y + 0.3, "off the ground, in the hand")
	assert_eq(board.area.collision_layer, 0, "and nobody else is offered it")
	assert_true(board.is_multiplayer_authority(), "The carrier's peer has the board")


func test_the_same_action_on_foot_gets_back_on_and_keeps_the_score() -> void:
	board.tricks.add("Kickflip", 100)
	await _get_off()
	assert_eq(board.tricks.score, 100, "Getting off banks the combo")
	Input.parse_input_event(_event(&"whistle"))
	await wait_physics_frames(3)
	assert_true(player.is_riding, "The action on foot gets back on")
	assert_eq(board.carrier_peer, 0)
	assert_eq(board.rider_peer, player.get_multiplayer_authority())
	assert_eq(board.transform, Transform3D.IDENTITY, "under the feet")
	assert_eq(board.tricks.score, 100, "and the run's score is still there")
	assert_eq(board.state, Skateboard.State.GROUND)


func test_getting_on_in_the_air_lands_on_the_board() -> void:
	await _get_off()
	player.warp_to(Transform3D(Basis(), Vector3(0.0, 2.0, 25.0)))
	player.velocity = Vector3(3.0, 2.0, 0.0)
	await get_tree().physics_frame
	Input.parse_input_event(_event(&"whistle"))
	await wait_physics_frames(3)
	assert_true(player.is_riding, "The action in the air gets on")
	assert_eq(board.state, Skateboard.State.AIR, "as an air")
	var frames: int = 0
	while board.state != Skateboard.State.GROUND and frames < 120:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.GROUND, "and the skater lands rolling")


func test_a_spine_button_on_foot_jumps_onto_the_board() -> void:
	await _get_off()
	await wait_physics_frames(5)
	assert_true(player.is_on_floor())
	Input.parse_input_event(_event(&"focus"))
	await wait_physics_frames(2)
	assert_true(player.is_riding, "Revert on foot gets on")
	assert_gt(player.velocity.y, Skateboard.ACID_DROP_JUMP_VELOCITY * 0.5, "with a jump, to drop into a ramp ahead")


func test_a_new_rider_starts_a_new_run() -> void:
	board.tricks.add("Kickflip", 100)
	await _get_off()
	assert_eq(board.tricks.score, 100)
	board._last_rider_peer = 99 # somebody else rode it last
	Input.parse_input_event(_event(&"whistle"))
	await wait_physics_frames(3)
	assert_true(player.is_riding)
	assert_eq(board.tricks.score, 0, "A different rider's score does not carry over")


func test_the_get_off_press_as_an_input_event_gets_off_once() -> void:
	Input.parse_input_event(_event(&"whistle"))
	Input.flush_buffered_events()
	await wait_physics_frames(3)
	assert_false(player.is_riding, "The press as an event, through the Riding state, gets off")
	assert_eq(board.carrier_peer, player.get_multiplayer_authority(), "with the board in hand")
	await wait_physics_frames(2)
	assert_false(player.is_riding, "and the same press does not get straight back on")
