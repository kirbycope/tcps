extends SceneTree
## Measures how the board moves, in numbers, so the feel can be compared with a reference (the Tony Hawk's
## Underground skater, whose tunables are in inches and seconds) rather than argued about. Runs headless:
##
##     godot --headless --path . -s tools/measure_run.gd
##
## It puts the rider on the board in the skate park and prints, as JSON: the push from standstill (speed
## against time, the top speed and when it was reached), coasting friction, a flat ollie tapped and held (air
## time and peak height), the turn rate at top speed, a quarter pipe air (air time, peak height and the speed
## kept), and a grind along the ledge (time on the rail, speed on and off it).
## Each measurement starts from the same spot on the open concrete, facing along it, so nothing runs off
## the edge of the park.

const PARK: String = "res://addons/tcps/scenes/demo/demo.tscn"
const START: Vector3 = Vector3(-38.0, 0.1, 30.0) ## West edge of the ground, well clear of the ramps.
const ALONG: Vector3 = Vector3(1.0, 0.0, 0.0) ## Heading east, 76 m of flat ahead.

var _park: Node
var _player: Player
var _results: Dictionary = {}
var _phase: int = 0
var _t: float = 0.0
var _placed: bool = false
var _samples: Array = []
var _air_t: float = 0.0
var _peak: float = 0.0
var _was_on_floor: bool = true
var _yaw_start: float = 0.0
var _speed_at_launch: float = 0.0
var _done: bool = false


func _initialize() -> void:
	_park = load(PARK).instantiate()
	root.add_child(_park)
	current_scene = _park


func _physics_process(delta: float) -> bool:
	if _done:
		return true
	if _player == null:
		_player = _park.get("player") as Player
		return false
	if not _player.is_riding:
		return false
	_t += delta
	match _phase:
		0: _push(delta)
		1: _coast(delta)
		2: _ollie(delta, "ollie_tap", 0.0)
		3: _ollie(delta, "ollie_held", 0.5)
		4: _turn(delta)
		5: _vert(delta)
		6: _grind(delta)
		_:
			print("MEASURE " + JSON.stringify(_results))
			_done = true
	return false


static func _send(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _speed() -> float:
	return _player.velocity.slide(Vector3.UP).length()


func _yaw() -> float:
	var f: Vector3 = _player.orientation.basis.z.slide(Vector3.UP).normalized()
	return atan2(f.x, f.z)


## Puts the rider at [param at] facing [param heading] with [param speed] along it; once per phase.
func _place(at: Vector3, heading: Vector3, speed: float) -> bool:
	if _placed:
		return false
	_placed = true
	_player.global_position = at
	_player.orientation.basis = Basis(Vector3.UP, atan2(heading.x, heading.z))
	_player.velocity = heading * speed
	_air_t = 0.0
	_peak = 0.0
	_was_on_floor = true
	return true


func _next() -> void:
	_phase += 1
	_t = 0.0
	_placed = false
	_samples = []
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"jump", &"sprint"]:
		Input.action_release(action)


## Hold forward from a standstill for six seconds, sampling speed every half second.
func _push(_delta: float) -> void:
	_place(START, ALONG, 0.0)
	Input.action_press(&"move_up")
	if _samples.is_empty() or _t - float(_samples[-1][0]) >= 0.5:
		_samples.append([snappedf(_t, 0.01), snappedf(_speed(), 0.01)])
	if _t >= 6.0:
		var top: float = 0.0
		var when: float = 0.0
		for s: Array in _samples:
			if float(s[1]) > top + 0.01:
				top = float(s[1])
				when = float(s[0])
		_results["push"] = {"speed_by_time": _samples, "top_speed": top, "reached_at": when}
		_next()


## From top speed, let go for four seconds and see how much speed rolling resistance takes.
func _coast(_delta: float) -> void:
	if _place(START, ALONG, 10.0):
		return
	if _samples.is_empty():
		_samples.append(_speed())
	if _t >= 4.0:
		_results["coast"] = {"from": snappedf(float(_samples[0]), 0.01), "to_after_4s": snappedf(_speed(), 0.01)}
		_next()


## At top speed press jump, hold it [param hold] seconds, let go, time the air and note the peak height.
func _ollie(delta: float, key: String, hold: float) -> void:
	if _place(START, ALONG, 10.0):
		return
	Input.action_press(&"move_up")
	if _t < 0.5:
		return
	if not _results.has(key):
		_send(&"jump", true) # the board reads its jump from input events, not by polling
		_results[key] = {"start_height": snappedf(_player.global_position.y, 0.001), "speed": snappedf(_speed(), 0.01), "hold": hold}
		return
	if _t < 0.5 + hold:
		return
	_send(&"jump", false)
	var on_floor: bool = _player.is_on_floor()
	if not on_floor:
		_air_t += delta
		_peak = maxf(_peak, _player.global_position.y - float(_results[key]["start_height"]))
		_was_on_floor = false
	elif not _was_on_floor and _air_t > 0.05:
		_results[key]["air_time"] = snappedf(_air_t, 0.01)
		_results[key]["peak_height"] = snappedf(_peak, 0.01)
		_results[key]["speed_after"] = snappedf(_speed(), 0.01)
		_next()
		return
	if _t > 6.0 + hold:
		_results[key]["air_time"] = -1.0
		_next()


## At top speed hold forward and left for two seconds; the yaw rate and the speed kept through the turn.
func _turn(_delta: float) -> void:
	if _place(START + Vector3(30.0, 0.0, 0.0), ALONG, 10.0):
		return
	Input.action_press(&"move_up")
	if _t < 0.5:
		return
	if _samples.is_empty():
		_yaw_start = _yaw()
		_samples.append(_speed())
		_samples.append(0.0) # the yaw turned so far, summed a frame at a time so a turn past a half circle still counts
	Input.action_press(&"move_left")
	_samples[1] = float(_samples[1]) + absf(wrapf(_yaw() - _yaw_start, -PI, PI))
	_yaw_start = _yaw()
	if _t >= 2.5:
		_results["turn"] = {"degrees_per_second_at_speed": snappedf(rad_to_deg(float(_samples[1])) / 2.0, 0.1), "speed_before": snappedf(float(_samples[0]), 0.01), "speed_after": snappedf(_speed(), 0.01)}
		_next()


## Ride at the quarter pipe (its face at x = -15, spanning z 0 to 8, run-up from the east) at full push and time the air.
func _vert(delta: float) -> void:
	if _place(Vector3(-6.0, 0.1, 4.0), Vector3(-1.0, 0.0, 0.0), 14.0): # the quarter pipe is extruded toward -z from z = 8, so its middle is z = 4
		_speed_at_launch = 0.0
		return
	var on_floor: bool = _player.is_on_floor()
	if on_floor and _player.get_floor_normal().y < 0.7:
		Input.action_release(&"move_up") # let go on the transition: holding Up at the lip breaks vert over the deck
		Input.action_release(&"sprint")
	elif on_floor:
		Input.action_press(&"move_up")
		Input.action_press(&"sprint") # crouched, the way a THUG player pushes at a wall
	if on_floor:
		if not _was_on_floor and _air_t > 0.1:
			_results["vert"] = {"air_time": snappedf(_air_t, 0.01), "peak_height": snappedf(_peak, 0.01), "speed_into_wall": snappedf(_speed_at_launch, 0.01), "speed_after_landing": snappedf(_player.velocity.length(), 0.01)}
			_next()
			return
		if _player.global_position.y < 0.5:
			_speed_at_launch = maxf(_speed_at_launch, _player.velocity.length())
	else:
		_air_t += delta
		_peak = maxf(_peak, _player.global_position.y)
	_was_on_floor = on_floor
	if _t > 10.0:
		_results["vert"] = {"air_time": -1.0, "note": "never left the wall or never landed", "y": snappedf(_player.global_position.y, 0.01)}
		_next()


## Thrown at the ledge's front rail in the air with Grind held: how long the grind lasts left alone (the meter
## runs, nobody balancing) and the speed on and off the rail.
func _grind(delta: float) -> void:
	var board: Skateboard = _player.riding as Skateboard
	if _place(Vector3(-3.6, 0.9, 15.7), ALONG, 6.0):
		_player.velocity.y = 2.0 # rising, so the ground snap does not pull the rider down before the rail
		board.state = Skateboard.State.AIR
		board._was_on_floor = false
		board._old_position = _player.global_position
		Input.action_press(&"action")
		_results["grind"] = {"took_rail": false}
		return
	if board.state == Skateboard.State.RAIL:
		if not bool(_results["grind"]["took_rail"]):
			_results["grind"] = {"took_rail": true, "took_after": snappedf(_t, 0.01), "speed_on": snappedf(board.rail_speed, 0.01), "time_on_rail": 0.0}
		_results["grind"]["time_on_rail"] = snappedf(float(_results["grind"]["time_on_rail"]) + delta, 0.01)
		return
	if bool(_results["grind"]["took_rail"]) and _player.is_on_floor():
		_results["grind"]["speed_after"] = snappedf(_speed(), 0.01)
		_results["grind"]["bailed"] = board._bail_timer > 0.0
		Input.action_release(&"action")
		_next()
	elif _t > 8.0:
		Input.action_release(&"action")
		_next()
