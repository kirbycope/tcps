class_name SkateBalance
extends RefCounted
## The one balance model behind manuals, grinds, lip tricks and skitches, after Neversoft's CManual in the Tony
## Hawk's Underground source (Code/Sk/Objects/manual.cpp). The needle leans further the further it already leans,
## at a rate that grows with time on the trick; the buttons push it back; with no button held it drifts on its own
## and never rests. Past [constant BAIL] either way the trick is over. THUG keeps the lean in units of 4096; here it
## is -1 to 1, with the same shape.
##
## One of these lives per kind of trick for the length of a combo, as THUG's mManual, mGrind, mLip and mSkitch do,
## and [method setup] carries the last trick's state into the next (CManual::SetUp): the lean comes back scaled by
## the kind's Lean_Repeat_Multiplier, the needle's speed by its Repeat_Multiplier, the time on the trick (so the
## instability) carries on, with two seconds added for landing back on the rail just left, and the "cheese" a
## trick left behind is added to the lean. The cheese is what stops a combo of grinds a few frames long each: a
## trick starts with a full helping and spends it over its CheeseFrames, so a quick hop to the next rail lands
## with most of it still to pay. A clean landing or a bail calls [method reset], and the next combo starts fresh.

# THUG's ManualParams, GrindParams, LipParams and SkitchParams from physics.q (Scripts/game/skater in kisak-thug),
# whose lean runs -4096..4096 and whose rates are per frame, scaled to a -1..1 lean per second: per-frame values
# times 60, over 4096. A (0, 10) stat range is read at its middle, 5.
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
const LIP_LEAN_MIN_SPEED: float = 10.0 * 60.0 / 4096.0 ## Lean_Min_Speed for a lip trick.
const LEAN_RND_SPEED: float = 20.0 * 60.0 / 4096.0 ## Lean_Rnd_Speed for a manual: the most that push can be.
const GRIND_RND_SPEED: float = 6.5 * 60.0 / 4096.0 ## Lean_Rnd_Speed 7.07..6 for a grind.
const DRIFT: float = 0.5 * 60.0 * 60.0 / 4096.0 ## rnd(50)/100 a frame: the needle's speed never rests.
const BAIL: float = 4000.0 / 4096.0 ## Lean_Bail_Angle: the edge of the meter.
const SAFE_BUTTON_PERIOD: float = 1.0 ## BalanceSafeButtonPeriod: for the first second of a trick a button pressed toward the lean ramps in, so one held at the start does not throw the needle.
# The carry-over between the tricks of a combo (CManual::SetUp, with THUG's units turned the same way).
const REPEAT_MIN: float = 1.0 * 60.0 / 4096.0 ## Repeat_Min: the needle's speed a fresh trick starts with (toward the tail of a manual, the nose of a nose manual, either side of a grind), and the least a carried one keeps.
const REPEAT_MULTIPLIER: float = 0.25 ## Repeat_Multiplier for a manual: the needle's speed comes back from the last manual of the combo scaled by this.
const GRIND_REPEAT_MULTIPLIER: float = 0.205 ## Repeat_Multiplier 0.31..0.1 for a grind.
const LIP_REPEAT_MULTIPLIER: float = 1.0 ## Repeat_Multiplier for a lip trick: the needle's speed comes back whole.
const LEAN_REPEAT_MULTIPLIER: float = 0.8 ## Lean_Repeat_Multiplier for a manual: the lean comes back scaled by this.
const GRIND_LEAN_REPEAT_MULTIPLIER: float = 0.5535 ## Lean_Repeat_Multiplier 0.607..0.5 for a grind.
const LIP_LEAN_REPEAT_MULTIPLIER: float = 1.0 ## Lean_Repeat_Multiplier for a lip trick.
const CHEESE: float = 700.0 / 4096.0 ## Cheese for a manual: the lean a manual leaves for the next manual of the combo...
const CHEESE_FRAMES: float = 100.0 ## CheeseFrames: ...less what drained away over this many sixtieths on the trick.
const GRIND_CHEESE: float = 2500.0 / 4096.0 ## Cheese for a grind: most of the meter, gone in half a second.
const GRIND_CHEESE_FRAMES: float = 30.0
const LIP_CHEESE: float = 2000.0 / 4096.0 ## Cheese 3000..1000 for a lip trick.
const LIP_CHEESE_FRAMES: float = 180.0
const SKITCH_CHEESE: float = 700.0 / 4096.0 ## SkitchParams: the same as a manual's, spent in a frame.
const SKITCH_CHEESE_FRAMES: float = 1.0
const SAME_GRIND_ADD_TIME: float = 2.0 ## Same_Grind_Add_Time: landing back on the rail just left, in the same combo, adds this to the time on the trick.
const NEW_GRIND_ADD_TIME: float = 0.143 ## New_Grind_Sub_Time -0.286..0 is subtracted, so a different rail adds this: THUG's note says anything less let a combo go round Rio for ever.

var rnd_speed: float = LEAN_RND_SPEED
var min_speed: float = LEAN_MIN_SPEED
var instable_rate: float = INSTABLE_RATE
var instable_base: float = INSTABLE_BASE
var lean_gravity: float = LEAN_GRAVITY
var lean_acc: float = LEAN_ACC
var repeat_multiplier: float = REPEAT_MULTIPLIER
var lean_repeat_multiplier: float = LEAN_REPEAT_MULTIPLIER
var full_cheese: float = CHEESE
var cheese_frames: float = CHEESE_FRAMES
var kind: String = "manual" ## What [method setup] was last given.
var lean: float = 0.0 ## -1 to 1; the meter shows it and past [constant BAIL] the trick is over.
var lean_dir: float = 0.0 ## The needle's own speed.
var time: float = 0.0 ## Seconds on this kind of trick in the combo, which the instability grows with (mManualTime).
var actual_time: float = 0.0 ## Seconds on this trick alone (mActualManualTime).
var cheese: float = 0.0 ## Lean waiting to be added to the next trick of the combo (mManualCheese), draining while this one lasts.
var _old_rail: int = -1 ## The rail of the last grind in the combo, to tell the same rail from a new one.


## Starts a trick, carrying the last one of the combo into it as THUG's SetUp does; [param kind] picks the
## parameters: a "grind" is a little steadier than a manual, as THUG's GrindParams are, a "lip" goes unstable much
## faster, as its LipParams do, a "skitch" is the gentlest (SkitchParams); anything else is a manual. For a grind,
## [param rail_id] says which rail, so landing back on the one just left can cost its two seconds.
func setup(kind_: String = "manual", rail_id: int = -1) -> void:
	kind = kind_
	rnd_speed = LEAN_RND_SPEED
	min_speed = LEAN_MIN_SPEED
	instable_rate = INSTABLE_RATE
	instable_base = INSTABLE_BASE
	lean_gravity = LEAN_GRAVITY
	lean_acc = LEAN_ACC
	repeat_multiplier = REPEAT_MULTIPLIER
	lean_repeat_multiplier = LEAN_REPEAT_MULTIPLIER
	full_cheese = CHEESE
	cheese_frames = CHEESE_FRAMES
	if kind == "grind":
		rnd_speed = GRIND_RND_SPEED
		instable_rate = GRIND_INSTABLE_RATE
		repeat_multiplier = GRIND_REPEAT_MULTIPLIER
		lean_repeat_multiplier = GRIND_LEAN_REPEAT_MULTIPLIER
		full_cheese = GRIND_CHEESE
		cheese_frames = GRIND_CHEESE_FRAMES
	elif kind == "lip":
		min_speed = LIP_LEAN_MIN_SPEED
		instable_rate = LIP_INSTABLE_RATE
		repeat_multiplier = LIP_REPEAT_MULTIPLIER
		lean_repeat_multiplier = LIP_LEAN_REPEAT_MULTIPLIER
		full_cheese = LIP_CHEESE
		cheese_frames = LIP_CHEESE_FRAMES
	elif kind == "skitch":
		instable_rate = SKITCH_INSTABLE_RATE
		instable_base = SKITCH_INSTABLE_BASE
		lean_gravity = SKITCH_LEAN_GRAVITY
		lean_acc = SKITCH_LEAN_ACC
		rnd_speed = SKITCH_RND_SPEED
		full_cheese = SKITCH_CHEESE
		cheese_frames = SKITCH_CHEESE_FRAMES
	actual_time = 0.0
	if kind == "grind":
		if _old_rail != -1:
			if rail_id == _old_rail:
				time += SAME_GRIND_ADD_TIME # jumped and landed on the same rail without ending the combo
			else:
				time = maxf(time + NEW_GRIND_ADD_TIME, 0.0)
				cheese = 0.0 # it is not cheesy to change rails
		_old_rail = rail_id
	if not is_zero_approx(lean_dir):
		lean_dir *= repeat_multiplier
		if absf(lean_dir) < REPEAT_MIN:
			lean_dir = REPEAT_MIN * signf(lean_dir)
	else:
		# No balance before this one in the combo: the needle sets off toward the way the kind falls
		lean_dir = REPEAT_MIN
		if kind == "nose_manual" or (kind != "manual" and randi() % 2 == 1):
			lean_dir = -lean_dir
	lean *= lean_repeat_multiplier
	lean += cheese * signf(lean)
	if absf(lean) > BAIL:
		lean = (BAIL + 0.001) * signf(lean) # the cheese alone is the bail: the first tick ends the trick
	cheese = full_cheese


## Forgets the combo: THUG's Reset, on a clean landing or a bail.
func reset() -> void:
	cheese = 0.0
	actual_time = 0.0
	time = 0.0
	lean = 0.0
	lean_dir = 0.0
	_old_rail = -1


## One tick with [param input] the button pressure along the meter (-1, 0 or 1; pressing toward the lean makes it
## worse, so the player presses against it). Returns true when the needle has gone off the end.
func update(delta: float, input: float) -> bool:
	actual_time += delta
	time += delta
	if cheese > 0.01:
		cheese = maxf(cheese - full_cheese / cheese_frames * 60.0 * delta, 0.0)
	var instability: float = instable_base + time * instable_rate
	lean += lean * lean_gravity * instability * delta
	lean += lean_dir * instability * delta
	if not is_zero_approx(input):
		var ramp: float = 1.0
		if signf(input) == signf(lean) and actual_time < SAFE_BUTTON_PERIOD:
			ramp = actual_time / SAFE_BUTTON_PERIOD # pressing toward the fall ramps in, so a button held from the start cannot throw the needle
		lean_dir += signf(input) * lean_acc * ramp * delta
	elif absf(lean_dir) < min_speed:
		var away: float = signf(lean_dir) if not is_zero_approx(lean_dir) else 1.0
		lean_dir = randf_range(min_speed, rnd_speed) * away
	else:
		lean_dir += randf_range(0.0, DRIFT) * signf(lean_dir) * delta
	return absf(lean) > BAIL
