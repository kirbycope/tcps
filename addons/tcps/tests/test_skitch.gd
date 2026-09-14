extends GutTest
## Purpose: skitching works the way THUG's does. Up held on the ground near the skitch point of a vehicle in the
## "skitchable" group takes it; the skater is pulled to the point, takes the vehicle's speed and balances on
## Left/Right; Down, the meter's end or an ollie lets go without a bail, rolling on at that speed.

const PARK_SCENE: PackedScene = preload("res://addons/tcps/scenes/skate_park.tscn")

var park: Node3D
var player: Player
var board: Skateboard
var truck: Node3D
var point: Node3D


func before_each() -> void:
	park = PARK_SCENE.instantiate()
	(park.get_node("MountTimer") as Timer).autostart = false
	add_child_autofree(park)
	player = park.get_node("Player")
	board = park.get_node("Skateboard")
	truck = park.get_node("TruckRoute/TruckFollow/Truck")
	point = truck.get_node("SkitchPoint")
	player.mount(board)
	await wait_physics_frames(3)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"action", &"sprint", &"focus"]:
		Input.action_release(action)


## Stands the rider a metre behind the truck's skitch point, rolling its way, with Up already held long enough.
func _behind_the_truck() -> void:
	var travel: Vector3 = (truck.global_transform.basis.z * -1.0).slide(Vector3.UP).normalized()
	var at: Vector3 = point.global_position - travel * 1.0
	player.warp_to(Transform3D(Basis.looking_at(-travel, Vector3.UP), Vector3(at.x, 0.05, at.z)))
	player.velocity = travel * 3.0
	board.state = Skateboard.State.GROUND
	board._clock = 10.0
	board._up_since = board._clock - Skateboard.SKITCH_HOLD_TIME - 0.05
	Input.action_press(&"move_up")


## Waits for the skitch to take, up to [param frames] physics frames (the warp lands first).
func _wait_for_skitch(frames: int = 20) -> void:
	var waited: int = 0
	while board.state != Skateboard.State.SKITCH and waited < frames:
		await get_tree().physics_frame
		waited += 1


func test_the_park_has_a_truck_that_drives_its_loop() -> void:
	assert_true(truck.is_in_group("skitchable"), "The truck can be skitched")
	assert_not_null(point, "with a point at its back")
	var before: Vector3 = truck.global_position
	var follow: PathFollow3D = park.get_node("TruckRoute/TruckFollow")
	var progress_before: float = follow.progress
	await wait_physics_frames(30)
	assert_almost_eq(follow.progress - progress_before, 5.0, 0.3, "and it drives at ten metres a second")
	assert_gt(truck.global_position.distance_to(before), 3.0, "the body with it")
	assert_true(follow.loop, "round its loop")


func test_up_held_behind_the_truck_takes_the_skitch_and_matches_its_speed() -> void:
	_behind_the_truck()
	await _wait_for_skitch()
	assert_eq(board.state, Skateboard.State.SKITCH, "Up held near the point is a skitch")
	assert_eq(board.trick, "skitch", "with its balance running")
	assert_eq(board.tricks.names(), ["Skitchin"], "worth THUG's five hundred")
	await wait_physics_frames(40)
	assert_eq(board.state, Skateboard.State.SKITCH, "still on")
	var truck_speed: float = board.skitch_velocity.slide(Vector3.UP).length()
	assert_almost_eq(truck_speed, 10.0, 1.0, "The truck's speed is read off its point")
	assert_lt(player.global_position.distance_to(point.global_position), 0.6, "The skater has been pulled to the point")
	assert_almost_eq(player.velocity.slide(Vector3.UP).length(), truck_speed, 1.5, "and travels at the truck's speed")


func test_far_from_the_truck_up_is_just_a_push() -> void:
	player.warp_to(Transform3D(Basis(), Vector3(0.0, 0.05, 0.0)))
	board.state = Skateboard.State.GROUND
	board._clock = 10.0
	board._up_since = board._clock - 1.0
	Input.action_press(&"move_up")
	await wait_physics_frames(3)
	assert_eq(board.state, Skateboard.State.GROUND, "Nothing to skitch at the park's middle")


func test_down_lets_go_and_the_skater_rolls_on_without_a_bail() -> void:
	_behind_the_truck()
	await _wait_for_skitch()
	await wait_physics_frames(30)
	assert_eq(board.state, Skateboard.State.SKITCH)
	Input.action_release(&"move_up")
	Input.action_press(&"move_down")
	await wait_physics_frames(2)
	assert_eq(board.state, Skateboard.State.GROUND, "Down lets go")
	assert_eq(board._bail_timer, 0.0, "without a bail")
	assert_gt(player.velocity.slide(Vector3.UP).length(), 5.0, "rolling on at the truck's speed")
	assert_eq(board.tricks.names(), ["Skitchin"], "with the skitch still in the combo, waiting to bank")
	assert_gt(board._bank_timer, 0.0)


func test_the_meters_end_lets_go_too() -> void:
	_behind_the_truck()
	await _wait_for_skitch()
	assert_eq(board.state, Skateboard.State.SKITCH)
	board.balance.lean = 1.0
	await wait_physics_frames(2)
	assert_eq(board.state, Skateboard.State.GROUND, "Off the meter the skater lets go (THUG's SkitchOut)")
	assert_eq(board._bail_timer, 0.0, "and it is not a bail")


func test_an_ollie_pops_off_the_truck() -> void:
	_behind_the_truck()
	await _wait_for_skitch()
	await wait_physics_frames(30)
	assert_eq(board.state, Skateboard.State.SKITCH)
	board._ollie(Skateboard.MAX_TENSE_TIME)
	assert_eq(board.state, Skateboard.State.AIR, "The pop lets go into the air")
	assert_gt(player.velocity.y, 5.0, "with the pop")
	assert_gt(player.velocity.slide(Vector3.UP).length(), 5.0, "and the truck's speed")
