class_name SkateBalance
extends RefCounted
## The one balance model behind manuals and grinds, after Neversoft's CManual in the Tony Hawk's Underground
## source (Code/Sk/Objects/manual.cpp). The needle leans further the further it already leans, at a rate that
## grows with time on the trick; the buttons push it back; with no button held it drifts on its own and never
## rests. Past [constant BAIL] either way the trick is over. THUG keeps the lean in units of 4096; here it is
## -1 to 1, with the same shape.

# THUG's ManualParams and GrindParams from physics.q, whose lean runs -4096..4096 and whose rates are per frame,
# scaled to a -1..1 lean per second: per-frame values times 60, over 4096.
const LEAN_GRAVITY: float = 0.02 * 60.0 ## Lean_Gravity_Stat: how much the lean feeds itself.
const INSTABLE_BASE: float = 1.0 ## Instable_Base: the instability the trick starts with.
const INSTABLE_RATE: float = 0.085 ## Instable_Rate 0.099..0.07 for a manual: how much instability each second on the trick adds.
const GRIND_INSTABLE_RATE: float = 0.097 ## Instable_Rate 0.104..0.09 for a grind.
const LIP_INSTABLE_RATE: float = 0.35 ## Instable_Rate 0.5..0.2 for a lip trick: a stall goes wobbly four times as fast as a manual.
const SKITCH_LEAN_GRAVITY: float = 0.01 * 60.0 ## SkitchParams: the lean feeds itself half as much...
const SKITCH_INSTABLE_BASE: float = 0.5 ## ...starts half as unstable...
const SKITCH_INSTABLE_RATE: float = 0.04 ## ...and grows half as fast as a manual's,
const SKITCH_RND_SPEED: float = 10.0 * 60.0 / 4096.0 ## with a smaller push,
const SKITCH_LEAN_ACC: float = 8.0 * 60.0 * 60.0 / 4096.0 ## and a little less from the buttons: a skitch is the easiest balance to hold.
const LEAN_ACC: float = 8.75 * 60.0 * 60.0 / 4096.0 ## Lean_Acc 10 with LEAN_ACC_DIFF 0.75..1.0: what a button does to the needle's speed, per second held.
const LEAN_MIN_SPEED: float = 5.0 * 60.0 / 4096.0 ## Lean_Min_Speed: below this the needle is given a new push.
const LEAN_RND_SPEED: float = 20.0 * 60.0 / 4096.0 ## Lean_Rnd_Speed for a manual: the most that push can be.
const GRIND_RND_SPEED: float = 6.5 * 60.0 / 4096.0 ## Lean_Rnd_Speed 7.07..6 for a grind.
const DRIFT: float = 0.5 * 60.0 * 60.0 / 4096.0 ## rnd(50)/100 a frame: the needle's speed never rests.
const START_RANGE: float = 0.15 ## Where the needle starts, either side of centre.
const BAIL: float = 4000.0 / 4096.0 ## Lean_Bail_Angle: the edge of the meter.

var rnd_speed: float = LEAN_RND_SPEED
var instable_rate: float = INSTABLE_RATE
var instable_base: float = INSTABLE_BASE
var lean_gravity: float = LEAN_GRAVITY
var lean_acc: float = LEAN_ACC
var lean: float = 0.0 ## -1 to 1; the meter shows it and past [constant BAIL] the trick is over.
var lean_dir: float = 0.0 ## The needle's own speed.
var time: float = 0.0 ## Seconds on the trick.


## Starts a trick with the needle a little off centre and already moving away from it, as THUG's SetUp does;
## [param kind] picks the parameters: a "grind" is a little steadier than a manual, as THUG's GrindParams are, a
## "lip" goes unstable much faster, as its LipParams do, a "skitch" is the gentlest (SkitchParams); anything else
## is a manual.
func setup(kind: String = "manual") -> void:
	rnd_speed = GRIND_RND_SPEED if kind == "grind" else LEAN_RND_SPEED
	instable_rate = INSTABLE_RATE
	instable_base = INSTABLE_BASE
	lean_gravity = LEAN_GRAVITY
	lean_acc = LEAN_ACC
	if kind == "grind":
		instable_rate = GRIND_INSTABLE_RATE
	elif kind == "lip":
		instable_rate = LIP_INSTABLE_RATE
	elif kind == "skitch":
		instable_rate = SKITCH_INSTABLE_RATE
		instable_base = SKITCH_INSTABLE_BASE
		lean_gravity = SKITCH_LEAN_GRAVITY
		lean_acc = SKITCH_LEAN_ACC
		rnd_speed = SKITCH_RND_SPEED
	time = 0.0
	lean = randf_range(-START_RANGE, START_RANGE)
	if is_zero_approx(lean):
		lean = START_RANGE * 0.5
	lean_dir = randf_range(LEAN_MIN_SPEED, rnd_speed) * signf(lean)


## One tick with [param input] the button pressure along the meter (-1, 0 or 1; pressing toward the lean makes it
## worse, so the player presses against it). Returns true when the needle has gone off the end.
func update(delta: float, input: float) -> bool:
	time += delta
	var instability: float = instable_base + time * instable_rate
	lean += lean * lean_gravity * instability * delta
	lean += lean_dir * instability * delta
	if not is_zero_approx(input):
		lean_dir += signf(input) * lean_acc * delta
	elif absf(lean_dir) < LEAN_MIN_SPEED:
		var away: float = signf(lean) if not is_zero_approx(lean) else 1.0
		lean_dir = randf_range(LEAN_MIN_SPEED, rnd_speed) * away
	else:
		lean_dir += randf_range(0.0, DRIFT) * signf(lean_dir) * delta
	return absf(lean) > BAIL
