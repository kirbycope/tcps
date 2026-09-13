extends GutTest
## Purpose: rails work the way THUG's do. A Rail is a Path3D the board finds only in the air with Grind held,
## within its snap distance and with a strong preference for the one it travels along; locking on puts the
## board on the rail with its speed along it plus the boost; the rail ends at its last point; an ollie leaves
## it; the grind runs the balance meter and a bail drops the board.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/skate_park.tscn")

var park: Node3D
var player: Player
var board: Skateboard
var ledge: Rail


func before_each() -> void:
	park = PARK_SCENE.instantiate()
	(park.get_node("MountTimer") as Timer).autostart = false
	add_child_autofree(park)
	player = park.get_node("Player")
	board = park.get_node("Skateboard")
	ledge = park.get_node("Ledge/FrontRail")
	player.mount(board)
	await wait_physics_frames(3)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action"]:
		Input.action_release(action)


## Throws the rider at the ledge's front rail from beside its start, in the air, travelling along it.
func _approach_the_ledge(grind: bool, speed: float = 6.0) -> void:
	# The ledge runs along x at z = 16; its front rail is at z = 15.7, 0.4 m up. Start just before its west end.
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(1.0, 0.0)), Vector3(-3.6, 0.9, 15.7)))
	player.velocity = Vector3(speed, 1.0, 0.0)
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._old_position = player.global_position
	if grind:
		Input.action_press(&"action")


func test_the_park_has_rails_on_the_ledge_the_handrail_and_the_bench() -> void:
	var rails: Array[Node] = get_tree().get_nodes_in_group("rails")
	var names: Array[String] = []
	for r: Node in rails:
		names.append(str(park.get_path_to(r)))
	for expected: String in ["Ledge/FrontRail", "Ledge/BackRail", "Handrail/Rail", "Bench/FrontRail", "Bench/BackRail"]:
		assert_has(names, expected, expected + " is a rail")
	assert_almost_eq(ledge.length(), 6.0, 0.01, "The ledge's rail runs its length")
	assert_almost_eq(ledge.point_at(0.0), Vector3(-3.0, 0.4, 15.7), Vector3.ONE * 0.01, "from its west end")
	assert_almost_eq(ledge.direction_at(3.0), Vector3.RIGHT, Vector3.ONE * 0.01, "heading east")


func test_the_rail_is_found_along_a_frames_move() -> void:
	var hit: Dictionary = ledge.closest_to_segment(Vector3(-2.0, 0.6, 15.7), Vector3(-1.9, 0.5, 15.7))
	assert_almost_eq(float(hit["distance"]), 0.1, 0.02, "The move passes a tenth of a metre above the rail")
	assert_almost_eq(float(hit["offset"]), 1.1, 0.05, "just over a metre along it")
	assert_almost_eq(hit["point"] as Vector3, Vector3(-1.9, 0.4, 15.7), Vector3.ONE * 0.02, "at the rail under the move")


func test_grind_held_in_the_air_takes_the_rail_and_rides_it_to_the_end() -> void:
	_approach_the_ledge(true)
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL, "With Grind held the board took the rail")
	assert_eq(board.rail, ledge, "the ledge's front edge")
	assert_eq(board.trick, "grind", "and the grind's meter is running")
	assert_almost_eq(player.global_position.z, 15.7, 0.02, "The board sits on the rail")
	assert_almost_eq(player.global_position.y, 0.4, 0.05, "at its height")
	assert_almost_eq(board.rail_speed, 6.0 + ledge.speed_boost, 0.3, "with its speed along it plus the boost")
	assert_eq(board.rail_sign, 1.0, "heading east, the way it was going")
	Input.action_release(&"action")
	# Keep the meter centred so the rail, not the balance, ends the grind
	frames = 0
	while board.state == Skateboard.State.RAIL and frames < 240:
		board.balance.lean = 0.0
		board.balance.lean_dir = 0.0
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.AIR, "Off the end of the rail the board is in the air")
	assert_gt(player.global_position.x, 2.9, "past the ledge's east end")
	assert_eq(board.trick, "", "with the grind over")
	assert_gt(player.velocity.x, 5.0, "still carrying its speed")


func test_without_grind_held_the_rail_is_passed_over() -> void:
	_approach_the_ledge(false)
	for i: int in 40:
		await get_tree().physics_frame
	assert_ne(board.state, Skateboard.State.RAIL, "Nothing held, no grind")


func test_the_board_takes_the_rail_backwards_when_heading_the_other_way() -> void:
	player.warp_to(Transform3D(Basis(Vector3.UP, atan2(-1.0, 0.0)), Vector3(3.6, 0.9, 15.7)))
	player.velocity = Vector3(-6.0, 1.0, 0.0)
	board.state = Skateboard.State.AIR
	board._was_on_floor = false
	board._old_position = player.global_position
	Input.action_press(&"action")
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	assert_eq(board.rail_sign, -1.0, "Travelling west is the rail's end to its start")
	assert_lt(player.velocity.x, 0.0, "and the velocity says so")


func test_an_ollie_leaves_the_rail_and_no_rail_is_taken_again_at_once() -> void:
	_approach_the_ledge(true)
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_eq(board.state, Skateboard.State.AIR, "The pop leaves the rail")
	assert_gt(player.velocity.y, Skateboard.OLLIE_MAX_SPEED - 0.5, "upward")
	assert_null(board.balance, "and the grind is over")
	await wait_physics_frames(6)
	assert_ne(board.state, Skateboard.State.RAIL, "Grind still held, the rail is not taken straight back")


func test_a_bail_on_the_rail_drops_the_board() -> void:
	seed(3)
	_approach_the_ledge(true)
	var frames: int = 0
	while board.state != Skateboard.State.RAIL and frames < 60:
		await get_tree().physics_frame
		frames += 1
	assert_eq(board.state, Skateboard.State.RAIL)
	var events: Array[String] = []
	board.trick_ended.connect(func(kind: String, bailed: bool) -> void: events.append(kind + (" bail" if bailed else "")))
	board.balance.lean = 0.99
	board.balance.lean_dir = 2.0
	await wait_physics_frames(3)
	assert_eq(events, ["grind bail"], "The needle off the end is a bail")
	assert_eq(board.state, Skateboard.State.AIR, "and the board is off the rail")
	assert_gt(board._bail_timer, 0.0, "with the rider a passenger for a moment")
