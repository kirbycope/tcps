extends SceneTree
## Plays a scripted run through the skate park with nobody at the controls, so the board can be filmed and
## the film picked apart frame by frame. An autopilot steers the rider through a list of legs (a point to
## reach, or a wall to ride up and come back down from) by pressing the same actions a player would, so what
## is recorded is the controller as shipped, not a cheat.
##
## Record it with Godot's movie writer, which draws every frame at a fixed rate however slow the capture is:
##
##     godot --path . --write-movie run.avi --fixed-fps 60 -s tools/record_run.gd
##
## The run quits on its own when the legs are done or after [constant MAX_SECONDS].

const PARK: String = "res://addons/tcps/scenes/skate_park.tscn"
const MAX_SECONDS: float = 90.0

var _driver: Driver


func _initialize() -> void:
	var park: Node = load(PARK).instantiate()
	root.add_child(park)
	current_scene = park
	_driver = Driver.new()
	_driver.park = park
	root.add_child(_driver)


func _process(_delta: float) -> bool:
	if _driver.finished or _driver.elapsed > MAX_SECONDS:
		print("record_run: done after %.1f s (%d legs)" % [_driver.elapsed, _driver.leg])
		return true
	return false


class Driver extends Node:
	## A leg is a target to steer at while holding forward. "air" legs end once the rider has left the ground and
	## landed again (a wall ridden up and back down); "point" legs end within reach of the target. "ollie" legs
	## pop once on the way; "spin" legs hold a direction in the air.
	const LEGS: Array[Dictionary] = [
		{"to": Vector3(-8, 0, 4), "kind": "point"}, # line up on the quarter pipe (a CSGPolygon3D extrudes toward -z, so it spans z 0 to 8)
		{"to": Vector3(-22, 0, 4), "kind": "air"}, # up the quarter pipe and back down
		{"to": Vector3(-8, 0, 4), "kind": "point"}, # roll away from it
		{"to": Vector3(-22, 0, 4), "kind": "air", "spin": -1.0, "grab": true}, # again, spinning with a grab in the air
		{"to": Vector3(-12, 0, 15.7), "kind": "point"}, # line up west of the ledge
		{"to": Vector3(8, 0, 15.7), "kind": "air", "ollie_at_x": -4.6, "grind": true}, # ollie onto its front rail and grind it out
		{"to": Vector3(10, 0, 19), "kind": "point"},
		{"to": Vector3(-16, 0, 20), "kind": "point"}, # line up on the handrail
		{"to": Vector3(0, 0, 20), "kind": "air", "ollie_at_x": -13.6, "grind": true}, # up onto the handrail
		{"to": Vector3(2, 0, 6), "kind": "point", "manual_at_x": -6.0}, # a manual across the flat
		{"to": Vector3(17, 0, 6), "kind": "point", "ollie_at_x": 9.5, "flip": true}, # a kickflip over the funbox
		{"to": Vector3(20, 0, 25), "kind": "point"},
		{"to": Vector3(28, 0, 25), "kind": "point"}, # into the wall, head on
		{"to": Vector3(0, 0, -10), "kind": "point"}, # into the half pipe's flat
		{"to": Vector3(-9, 0, -10), "kind": "air"}, # left wall
		{"to": Vector3(9, 0, -10), "kind": "air", "ollie": true}, # right wall, pop at the lip
		{"to": Vector3(0, 0, 0), "kind": "point", "ollie_at_x": -2.0, "spin": 1.0}, # a flat ollie with a 180 on the way out
	]
	const REACH: float = 1.5

	var park: Node
	var elapsed: float = 0.0
	var leg: int = 0
	var finished: bool = false
	var _player: Player
	var _was_on_floor: bool = true
	var _left_ground: bool = false
	var _ollied: bool = false
	var _manualled: bool = false
	var _tricked: bool = false
	var _leg_time: float = 0.0

	func _physics_process(delta: float) -> void:
		elapsed += delta
		if _player == null:
			_player = park.get("player") as Player
			return
		if not _player.is_riding:
			return # the park's MountTimer has not put them on the board yet
		if leg >= LEGS.size():
			_release_all()
			finished = true
			return
		var spec: Dictionary = LEGS[leg]
		_leg_time += delta
		var on_floor: bool = _player.is_on_floor()
		if _was_on_floor and not on_floor:
			_left_ground = true
		var landed: bool = _left_ground and on_floor and not _was_on_floor
		_was_on_floor = on_floor

		var to: Vector3 = spec["to"]
		var here: Vector3 = _player.global_position
		var flat: Vector3 = (to - here).slide(Vector3.UP)
		var kind: String = spec["kind"]
		var done: bool = false
		if kind == "point":
			done = flat.length() < REACH or _leg_time > 12.0
		else:
			done = (landed and _leg_time > 0.5) or _leg_time > 12.0
		if done:
			_next_leg()
			return

		# Steer: press left or right until the heading lines up with the way to the target, with Down for THUG's
		# sharp turn when the target is well off the nose; push crouched (sprint), as a THUG player holds X, or a
		# standing push never reaches the top of a 3.3 m wall; and let go of everything on a transition and in
		# the air, since Up at the moment of leaving the wall is THUG's break vert, over the deck
		var heading: Vector3 = _player.orientation.basis.z.slide(Vector3.UP).normalized()
		var angle: float = heading.signed_angle_to(flat.normalized(), Vector3.UP)
		var in_air: bool = not on_floor
		var on_transition: bool = on_floor and _player.get_floor_normal().y < 0.7
		var sharp: bool = on_floor and not on_transition and absf(angle) > deg_to_rad(45.0)
		if on_transition or in_air or sharp:
			Input.action_release(&"move_up")
			Input.action_release(&"sprint")
		else:
			Input.action_press(&"move_up")
			Input.action_press(&"sprint")
		if sharp:
			Input.action_press(&"move_down")
		else:
			Input.action_release(&"move_down")
		if in_air and spec.has("spin"):
			var b: Skateboard = _player.riding as Skateboard
			if absf(b._spin_tally) < 150.0:
				_press_turn(spec["spin"]) # up to a half turn and a bit, inside the slop of the 180
			else:
				_release_turn()
		elif absf(angle) > 0.08 and not in_air:
			_press_turn(signf(angle))
		else:
			_release_turn()

		# Ollie where the leg asks for one, holding Grind through the air when it asks for that too
		if spec.has("ollie_at_x") and not _ollied and on_floor and absf(here.x - float(spec["ollie_at_x"])) < 0.6:
			_tap(&"jump")
			_ollied = true
			if spec.get("grind", false):
				Input.action_press(&"action")
		if spec.get("grind", false) and _ollied and landed:
			Input.action_release(&"action")
		# Tricks in the air: a flip a moment after the pop, a grab held through the air
		if spec.get("flip", false) and _ollied and in_air and not _tricked and _leg_time > 0.0:
			_tricked = true
			_send(&"attack", true)
			get_tree().create_timer(0.1, false, true).timeout.connect(_send.bind(&"attack", false))
		if spec.get("grab", false) and in_air and not _tricked and _left_ground:
			_tricked = true
			Input.action_press(&"sprint")
			_send(&"sprint", true)
		if spec.get("grab", false) and _tricked and landed:
			Input.action_release(&"sprint")
		# A manual: Up then Down, tapped as events the way the board reads them
		if spec.has("manual_at_x") and not _manualled and on_floor and absf(here.x - float(spec["manual_at_x"])) < 0.6:
			_manualled = true
			_send(&"move_up", true)
			_send(&"move_up", false)
			_send(&"move_down", true)
			_send(&"move_down", false)
		if spec.get("ollie", false) and not _ollied and on_floor and _player.get_floor_normal().angle_to(Vector3.UP) > deg_to_rad(60.0):
			_tap(&"jump")
			_ollied = true

	func _press_turn(direction: float) -> void:
		# turn_amount = -motion.x, so move_right (positive x) turns clockwise
		if direction < 0.0:
			Input.action_release(&"move_left")
			Input.action_press(&"move_right")
		else:
			Input.action_release(&"move_right")
			Input.action_press(&"move_left")

	func _release_turn() -> void:
		Input.action_release(&"move_left")
		Input.action_release(&"move_right")

	## The board reads its jump from input events rather than by polling, so a tap has to be a real event; the
	## ollie is charged by the hold, so the button stays down a third of a second before it comes up.
	func _tap(action: StringName) -> void:
		_send(action, true)
		get_tree().create_timer(0.3, false, true).timeout.connect(_send.bind(action, false))

	static func _send(action: StringName, pressed: bool) -> void:
		var event: InputEventAction = InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)

	func _next_leg() -> void:
		print("record_run: leg %d done at %.1f s, at %s" % [leg, elapsed, _player.global_position])
		leg += 1
		_leg_time = 0.0
		_left_ground = false
		_ollied = false
		_manualled = false
		_tricked = false
		_release_turn()
		Input.action_release(&"action")

	func _release_all() -> void:
		for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"sprint", &"action"]:
			Input.action_release(action)
