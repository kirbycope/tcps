class_name SkateBalance
extends RefCounted
## The one balance model behind manuals and grinds, after Neversoft's CManual in the Tony Hawk's Underground
## source (Code/Sk/Objects/manual.cpp). The needle leans further the further it already leans, at a rate that
## grows with time on the trick; the buttons push it back; with no button held it drifts on its own and never
## rests. Past [constant BAIL] either way the trick is over. THUG keeps the lean in units of 4096; here it is
## -1 to 1, with the same shape.

const LEAN_GRAVITY: float = 1.2 ## Lean_Gravity_Stat: how much the lean feeds itself.
const INSTABLE_BASE: float = 1.0 ## Instable_base: the instability the trick starts with.
const INSTABLE_RATE: float = 0.35 ## Instable_Rate: how much instability each second on the trick adds.
const LEAN_ACC: float = 4.0 ## Lean_Acc: what a button does to the needle's speed, per second held.
const LEAN_MIN_SPEED: float = 0.15 ## Lean_Min_Speed: below this the needle is given a new push.
const LEAN_RND_SPEED: float = 0.35 ## Lean_Rnd_Speed: the most that push can be.
const START_RANGE: float = 0.15 ## Where the needle starts, either side of centre.
const BAIL: float = 1.0 ## Lean_Bail_Angle: the edge of the meter.

var lean: float = 0.0 ## -1 to 1; the meter shows it and past [constant BAIL] the trick is over.
var lean_dir: float = 0.0 ## The needle's own speed.
var time: float = 0.0 ## Seconds on the trick.


## Starts a trick with the needle a little off centre and already moving away from it, as THUG's SetUp does.
func setup() -> void:
	time = 0.0
	lean = randf_range(-START_RANGE, START_RANGE)
	if is_zero_approx(lean):
		lean = START_RANGE * 0.5
	lean_dir = randf_range(LEAN_MIN_SPEED, LEAN_RND_SPEED) * signf(lean)


## One tick with [param input] the button pressure along the meter (-1, 0 or 1; pressing toward the lean makes it
## worse, so the player presses against it). Returns true when the needle has gone off the end.
func update(delta: float, input: float) -> bool:
	time += delta
	var instability: float = INSTABLE_BASE + time * INSTABLE_RATE
	lean += lean * LEAN_GRAVITY * instability * delta
	lean += lean_dir * instability * delta
	if not is_zero_approx(input):
		lean_dir += signf(input) * LEAN_ACC * delta
	elif absf(lean_dir) < LEAN_MIN_SPEED:
		var away: float = signf(lean) if not is_zero_approx(lean) else 1.0
		lean_dir = randf_range(LEAN_MIN_SPEED, LEAN_RND_SPEED) * away
	else:
		lean_dir += randf_range(0.0, 0.25) * signf(lean_dir) * delta
	return absf(lean) > BAIL
