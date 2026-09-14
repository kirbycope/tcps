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
## The run quits on its own when the legs are done or after [constant MAX_SECONDS]. Two environment variables help
## when one leg misbehaves: TCPS_FIRST_LEG=n starts at leg n with the rider placed at the previous leg's target,
## and TCPS_TRACE=1 prints the board's state every tick, which works headless too (no --write-movie needed).

const PARK: String = "res://addons/tcps/scenes/skate_park.tscn"
const MAX_SECONDS: float = 180.0

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
		{"to": Vector3(9, 0, -10), "kind": "air", "ollie": true, "flip_direction": Vector2(-1.0, -1.0), "double": true}, # right wall, pop at the lip, a varial kickflip (Down-Left) in the air, flipped again into a 360 Flip
		{"to": Vector3(0, 0, 0), "kind": "point", "ollie_at_x": -2.0, "spin": 1.0}, # a flat ollie with a 180 on the way out
		{"to": Vector3(-8, 0, 4), "kind": "point"}, # line up on the quarter pipe again
		{"to": Vector3(-22, 0, 4), "kind": "air", "lip": true}, # a lip trick on its coping, then drop back in
		{"to": Vector3(-8, 0, 4), "kind": "point"},
		{"to": Vector3(-30, 0, 12), "kind": "point"}, # round to the back of the quarter pipe
		{"to": Vector3(-27, 0, 4), "kind": "point"},
		{"to": Vector3(-10, 0, 4), "kind": "air", "acid": true}, # up the bank, over the deck and acid drop into the pipe
		# A crouched push turns with a four metre radius, so each run-in below is a straight line the rider is
		# already heading along when the leg starts; a tap's pop lands a third of a second (4.5 m) after the tap
		{"to": Vector3(30, 0, 14), "kind": "point"}, # east across the park, north of the funbox
		{"to": Vector3(32, 0, 0), "kind": "point"}, # south, to turn west onto the spine's line
		{"to": Vector3(8, 0, -4), "kind": "air", "spine": true}, # up its near face and transfer to the far one
		{"to": Vector3(14, 0, 30), "kind": "point"}, # line up on the wall for a wall ride, a shallow angle
		{"to": Vector3(27, 0, 19), "kind": "air", "ollie_at_x": 22.0, "grind": true}, # ollie into the wall with Grind and ride it
		{"to": Vector3(24, 0, 11), "kind": "point"}, # south along the wall's line, the turn west ending north of the funbox
		{"to": Vector3(10, 0, 9), "kind": "point"}, # west, north of the funbox
		{"to": Vector3(6, 0, 18), "kind": "point"}, # north, west of the bench, to turn east onto the wall's line
		{"to": Vector3(28, 0, 25), "kind": "air", "ollie_at_x": 17.5, "wallplant": true}, # pop about 22, Ollie again at the wall
		{"to": Vector3(10, 0, 25), "kind": "point"},
		{"to": Vector3(0, 0, 25), "kind": "walk"}, # get off with the board in hand, walk, jump, and get back on in the air
		{"to": Vector3(-8, 0, 22), "kind": "point"},
		{"to": Vector3(-22, 0, 26), "kind": "point"}, # west, then down the park's west side to the truck's road at the south end, arriving heading east along its near side (the truck runs east along z = -33)
		{"to": Vector3(-30, 0, 14), "kind": "point"},
		{"to": Vector3(-30, 0, -20), "kind": "point"},
		{"to": Vector3(-38, 0, -30), "kind": "point"},
		{"to": Vector3(-30, 0, -35), "kind": "point"},
		{"to": Vector3(30, 0, -35), "kind": "skitch"}, # brake until the truck comes round the corner, push after it holding Up, hang on, pop off
		{"to": Vector3(10, 0, -20), "kind": "point"},
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
	var _started: bool = false
	var _skitch_since: float = 0.0
	var _skitch_go: bool = false
	var _hold_until: float = 0.0 ## Leg time until which a trick's direction is held and the steering keeps its hands off the stick.
	var _trace: bool = OS.get_environment("TCPS_TRACE") != ""

	func _physics_process(delta: float) -> void:
		elapsed += delta
		if _player == null:
			_player = park.get("player") as Player
			return
		if not _player.is_riding and not _started:
			return # the park's MountTimer has not put them on the board yet
		if not _started:
			_started = true
			var first: String = OS.get_environment("TCPS_FIRST_LEG")
			if first.is_valid_int() and int(first) > 0 and int(first) < LEGS.size():
				leg = int(first)
				var at: Vector3 = LEGS[leg - 1]["to"]
				_player.warp_to(Transform3D(Basis(), Vector3(at.x, 0.1, at.z)))
		if _trace and not (_player.riding is Skateboard):
			print("trace %.2f leg %d on foot pos %s vel %s floor %s motion %s" % [elapsed, leg, _player.global_position, _player.velocity, _player.is_on_floor(), _player.player_input.motion])
		if _trace and _player.riding is Skateboard:
			var b: Skateboard = _player.riding as Skateboard
			var truck_node: Node3D = park.get_node_or_null("TruckRoute/TruckFollow/Truck") as Node3D
			print("trace %.2f leg %d state %d pos %s vel %s vert %s transfer %s up_since %.2f motion %s truck %s trick %s combo %s" % [elapsed, leg, b.state, _player.global_position, _player.velocity, b.vert_normal, b._transferring, b._up_since, _player.player_input.motion, truck_node.global_position if truck_node else Vector3.ZERO, b.air_trick, b.tricks.names()])
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
		if kind == "skitch":
			# Roll east beside the road with Up held (THUG's skitch is Up held near a car); once on, ride two
			# seconds and pop off; the leg is over once the skater is down again
			var riding_board: Skateboard = _player.riding as Skateboard
			if riding_board == null:
				_next_leg()
				return
			if riding_board.state == Skateboard.State.SKITCH:
				if not _tricked:
					_tricked = true
					_skitch_since = _leg_time
				Input.action_release(&"move_up")
				_release_turn()
				if _leg_time - _skitch_since > 2.0 and not _ollied:
					_ollied = true
					_tap(&"jump")
			elif not _tricked:
				# Brake and wait until the truck has come round the south-west corner onto the near lane and is
				# just ahead; then push after it (crouched, faster than the truck) with Up held for the skitch
				var truck: Node3D = park.get_node_or_null("TruckRoute/TruckFollow/Truck") as Node3D
				var truck_ahead: bool = truck != null and truck.global_position.z < -29.5 and truck.global_position.x < -19.0
				if truck_ahead:
					_skitch_go = true
				if not _skitch_go:
					Input.action_release(&"move_up")
					Input.action_release(&"sprint")
					Input.action_press(&"move_down")
					_release_turn()
				else:
					Input.action_release(&"move_down")
					var heading_now: Vector3 = _player.orientation.basis.z.slide(Vector3.UP).normalized()
					var angle_now: float = heading_now.signed_angle_to(flat.normalized(), Vector3.UP)
					if absf(angle_now) > 0.08:
						_press_turn(signf(angle_now))
					else:
						_release_turn()
					Input.action_press(&"move_up")
					Input.action_press(&"sprint")
			if (_tricked and _ollied and on_floor and _leg_time - _skitch_since > 3.0) or _leg_time > 24.0:
				_next_leg()
			return
		if kind == "walk":
			# Off the board (the dismount action), a second's walk holding forward, a jump, and the same action in
			# the air to land back on the board; the leg is over once the skater is riding and down again
			if _leg_time < 0.1:
				_release_all()
			elif _leg_time < 0.3 and _player.is_riding and not _ollied:
				_ollied = true
				_tap(&"whistle")
			elif not _player.is_riding and _leg_time < 1.6:
				Input.action_press(&"move_up")
			elif not _player.is_riding and not _tricked:
				_tricked = true
				Input.action_release(&"move_up")
				Input.action_press(&"jump") # the Player on foot reads the action's state as well as the event
				_tap(&"jump")
				get_tree().create_timer(0.3, false, true).timeout.connect(_release.bind(&"jump"))
				get_tree().create_timer(0.7, false, true).timeout.connect(_tap.bind(&"whistle")) # after the jump's wind-up, in the air
			if _tricked and _player.is_riding and on_floor and _leg_time > 2.5 or _leg_time > 8.0:
				_next_leg()
			return
		if kind == "point":
			done = flat.length() < REACH or _leg_time > 12.0
		else:
			var tricked: bool = _tricked or not (spec.has("acid") or spec.has("spine") or spec.has("lip"))
			done = (landed and _leg_time > 0.5 and tricked) or _leg_time > 14.0
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
		var riding: Skateboard = _player.riding as Skateboard
		var on_transition: bool = on_floor and (_player.get_floor_normal().y < 0.7 or (riding != null and riding.last_floor_normal.y < 0.7))
		var sharp: bool = on_floor and not on_transition and absf(angle) > deg_to_rad(45.0)
		if on_transition or in_air or sharp:
			Input.action_release(&"move_up")
			Input.action_release(&"sprint")
		else:
			Input.action_press(&"move_up")
			Input.action_press(&"sprint")
		var holding_a_direction: bool = _leg_time < _hold_until # a trick's direction is being held: leave the stick alone
		if sharp:
			Input.action_press(&"move_down")
		elif not holding_a_direction:
			Input.action_release(&"move_down")
		if in_air and spec.has("spin") and _player.riding is Skateboard:
			var b: Skateboard = _player.riding as Skateboard
			if absf(b._spin_tally) < 150.0:
				_press_turn(spec["spin"]) # up to a half turn and a bit, inside the slop of the 180
			else:
				_release_turn()
		elif absf(angle) > 0.08 and not in_air:
			_press_turn(signf(angle))
		elif not holding_a_direction:
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
			if spec.get("double", false):
				get_tree().create_timer(0.2, false, true).timeout.connect(_send.bind(&"attack", true)) # again mid-flip: the extra
				get_tree().create_timer(0.3, false, true).timeout.connect(_send.bind(&"attack", false))
		if spec.has("flip_direction") and _ollied and in_air and not _tricked and _left_ground:
			_tricked = true
			_hold_until = _leg_time + 0.2
			var direction: Vector2 = spec["flip_direction"]
			if direction.x < 0.0:
				Input.action_press(&"move_left")
			elif direction.x > 0.0:
				Input.action_press(&"move_right")
			if direction.y < 0.0:
				Input.action_press(&"move_down")
			elif direction.y > 0.0:
				Input.action_press(&"move_up")
			get_tree().create_timer(0.05, false, true).timeout.connect(_send.bind(&"attack", true))
			get_tree().create_timer(0.15, false, true).timeout.connect(_send.bind(&"attack", false))
			get_tree().create_timer(0.2, false, true).timeout.connect(_release_all)
			if spec.get("double", false):
				get_tree().create_timer(0.3, false, true).timeout.connect(_send.bind(&"attack", true)) # again mid-flip: the extra
				get_tree().create_timer(0.4, false, true).timeout.connect(_send.bind(&"attack", false))
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
		if spec.get("ollie", false) and not _ollied and on_floor and _player.get_floor_normal().angle_to(Vector3.UP) > deg_to_rad(60.0) and _player.velocity.y > 2.0:
			_tap(&"jump")
			_ollied = true
		var board: Skateboard = _player.riding as Skateboard
		if board == null:
			return
		# A lip: Grind while rising in vert air; once on the coping, let go, hold the stall a second and pop off
		if spec.has("lip"):
			if in_air and board.vert_normal != Vector3.ZERO and _player.velocity.y > 0.0 and board.state == Skateboard.State.AIR and not _tricked:
				Input.action_press(&"action")
			elif board.state == Skateboard.State.LIP:
				Input.action_release(&"action")
				if not _tricked:
					_tricked = true
					get_tree().create_timer(1.0, false, true).timeout.connect(_tap.bind(&"jump"))
			else:
				Input.action_release(&"action")
		# A transfer: hold a spine button while rising in vert air; an acid drop: hold it in the air off the deck
		if spec.has("spine") and in_air and board.vert_normal != Vector3.ZERO:
			Input.action_press(&"focus")
			if board._transferring:
				_tricked = true
		elif spec.has("acid") and in_air and _left_ground:
			Input.action_press(&"focus")
			if board._transferring:
				_tricked = true
		elif spec.has("spine") or spec.has("acid"):
			Input.action_release(&"focus")
		# A wallplant: press Ollie again as the wall is reached
		if spec.has("wallplant") and _ollied and in_air and not _tricked and here.x > 23.0:
			_tricked = true
			_tap(&"jump")

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

	## A timer's callable must be a script method: one bound to a native singleton method crashes Godot at exit.
	static func _release(action: StringName) -> void:
		Input.action_release(action)

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
		Input.action_release(&"focus")

	func _release_all() -> void:
		Input.action_release(&"focus")
		for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"sprint", &"action", &"whistle"]:
			Input.action_release(action)
