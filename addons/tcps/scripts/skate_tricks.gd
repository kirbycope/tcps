class_name SkateTricks
extends RefCounted
## The trick layer and the score, after THUG's trick and score code (CTrickComponent, Score in
## Code/Sk/Modules/Skate/score.cpp) and its trick scripts (airtricks.q, grindscripts.q, manualtricks.q,
## liptricks.q, walltricks.q, tricks.q in the decompiled scripts): which trick a button and a direction name, what
## each is worth, and the combo they add up to. A combo is every trick since the last clean landing; each trick's
## points are its base times the spin attached to it (SPIN_MULT_VALUES) times its depreciation for having been done
## before in the run (DEPREC_VALUES), summed and multiplied by the number of tricks, banked into [member score] on a
## clean landing and lost in a bail. Grinds, manuals and reverts are the links that carry a combo across a landing.
## The special meter fills as the combo grows, lights at [constant SPECIAL_FULL], drains all the while, and lit it
## adds three to every stat and opens the special tricks.

# The points are THUG's own, from its trick scripts, and the tables are the created skater's default mapping
# (CustomTricks_default in protricks.q, with HawkLip for the lips, and GrindTrickList): eight directions, the
# diagonals THUG's d-pad gives when two directions are held. A button with nothing held does the Left slot's
# trick, as THPS has always done; THUG has no slot for it.
const FLIPS: Dictionary = { ## Square in THUG. Direction held at the press, then the name and the points.
	"": ["Kickflip", 100],
	"left": ["Kickflip", 100],
	"right": ["Heelflip", 100],
	"up": ["Impossible", 100],
	"down": ["Pop Shove-It", 100],
	"up_left": ["Hardflip", 300],
	"up_right": ["Inward Heelflip", 350],
	"down_left": ["Varial Kickflip", 300],
	"down_right": ["Varial Heelflip", 300],
}
const GRABS: Dictionary = { ## Circle in THUG.
	"": ["Melon", 300],
	"left": ["Melon", 300],
	"right": ["Indy", 300],
	"up": ["Nosegrab", 300],
	"down": ["Tailgrab", 300],
	"up_left": ["Japan", 350],
	"up_right": ["Madonna", 750],
	"down_left": ["Benihana", 300],
	"down_right": ["Airwalk", 450],
}
const GRINDS: Dictionary = { ## Triangle in THUG, by the direction held when a rail is taken along the travel (GrindTrickList's parallel entries).
	"": ["50-50", 100],
	"left": ["Tailslide", 150],
	"right": ["Noseslide", 150],
	"up": ["Nosegrind", 100],
	"down": ["5-0", 100],
	"up_left": ["Overcrook", 125],
	"up_right": ["Crooked", 125],
	"down_left": ["Smith", 125],
	"down_right": ["Feeble", 125],
}
const ACROSS_GRINDS: Dictionary = { ## The same, for a rail taken across the travel: the slides (GrindTrickList's other entries).
	"": ["Boardslide", 200],
	"left": ["Boardslide", 200],
	"right": ["Lipslide", 200],
}
const MANUALS: Dictionary = {"manual": ["Manual", 100], "nose_manual": ["Nose Manual", 100]}
const LIPS: Dictionary = { ## Grind at the lip of a vert wall on the way up, by the direction held (HawkLip; DefaultLipTrick with nothing held).
	"": ["Nose Stall", 300],
	"left": ["Varial Invert To Fakie", 450],
	"right": ["BS Boneless", 550],
	"up": ["FS Noseblunt", 550],
	"down": ["Invert", 500],
	"up_left": ["Andrecht Invert", 550],
	"up_right": ["The Switcheroo", 600],
	"down_left": ["Gymnast Plant", 575],
	"down_right": ["One Foot Invert", 500],
}
const EXTRAS: Dictionary = { ## ExtraTricks: the button pressed again mid-trick turns the trick into this one (and again, into that one's).
	"Kickflip": ["Double Kickflip", 500],
	"Double Kickflip": ["Triple Kickflip", 1000],
	"Heelflip": ["Double Heelflip", 500],
	"Double Heelflip": ["Triple Heelflip", 1000],
	"Pop Shove-It": ["360 Shove-It", 500],
	"360 Shove-It": ["540 Shove-It", 1000],
	"Impossible": ["Double Impossible", 500],
	"Double Impossible": ["Triple Impossible", 1000],
	"Hardflip": ["360 Hardflip", 500],
	"Varial Kickflip": ["360 Flip", 550],
	"Varial Heelflip": ["360 Heelflip", 500],
	"Inward Heelflip": ["360 Inward Heelflip", 500],
	"Sal Flip": ["360 Sal Flip", 1150],
	"Ollie North": ["Ollie North Back Foot Flip", 1050],
	"Melon": ["Method", 400],
	"Indy": ["Stiffy", 500],
	"Nosegrab": ["Rocket Air", 400],
	"Tailgrab": ["One Foot Tailgrab", 500],
	"Japan": ["One Foot Japan", 800],
	"Madonna": ["Judo", 1150],
	"Benihana": ["Sacktap", 1500],
	"Airwalk": ["Christ Air", 550],
}
const DOUBLE_TAPS: Dictionary = { ## Two taps of one direction then the button (Air_U_U_Square, GrindTricks): these instead of the direction's trick.
	"flip": {"up,up": ["Sal Flip", 900], "down,down": ["Ollie North", 169]},
	"grind": {"up,up": ["Nosebluntslide", 250], "down,down": ["Bluntslide", 250]},
}
const OLLIE: Array = ["Ollie", 75] ## What a spin with no trick in the air attaches to.
const WALLRIDE: Array = ["Wallride", 200]
const WALLPLANT: Array = ["Wallplant", 750]
const SPINE_TRANSFER: Array = ["Spine Transfer", 250] ## TRANSFER_POINTS, for the hip too.
const HIP_TRANSFER: Array = ["Hip Transfer", 250]
const ACID_DROP: Array = ["Acid Drop", 250] ## ACID_DROP_POINTS.
const REVERT: Array = ["Revert", 100]
const SKITCH: Array = ["Skitchin", 500] ## Hanging off the back of a moving vehicle (groundtricks.q).
const SPECIALS: Dictionary = { ## The three special slots THUG gives a created skater (skater_profile.q): two directions then the button, within SPECIAL_WINDOW, while the meter is lit.
	"flip": {"taps": ["left", "right"], "trick": ["Kickflip Underflip", 1000]},
	"grab": {"taps": ["right", "down"], "trick": ["McTwist", 5000]},
	"grind": {"taps": ["right", "down"], "trick": ["Tailblock Slide", 500]},
}
const SPECIAL_WINDOW: float = 0.4 ## TripleInOrder's 400 ms: both taps and the button inside it.
const SPIN_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5] ## SPIN_MULT_VALUES {2..7} over 2, by half turns; past a 900 the last stands.
const DEPRECIATION: Array[int] = [100, 75, 50, 25, 10] ## DEPREC_VALUES: per cent of the base for the first, second... time a trick is done in the run.
const SPIN_SLOP: float = 60.0 ## spin_count_slop: a landing this far short of the next half turn still counts it.
const FLIP_TIME: float = 0.45 ## Seconds a flip trick takes; landing before it is done is a bail.
const GRAB_MIN_TIME: float = 0.25 ## A grab shorter than this is not one.
const SPECIAL_FULL: float = 3000.0 ## The meter's top, in points (Score::Update).
const SPECIAL_DRAIN: float = 50.0 ## Points a second the meter loses.
const SPECIAL_LIT_DRAIN: float = 200.0 ## And while lit.
const STAT: float = 0.5 ## Where in each stat's range the board sits: 5 of 10.
const SPECIAL_STAT: float = 0.8 ## And with the meter lit: +3 (CSkater::GetStat).

var score: int = 0 ## Points banked by clean landings.
var combo: Array[Dictionary] = [] ## The tricks since the last clean landing, in order: {"name", "points", "spin", "spin_text", "uses"}.
var last_banked: int = 0 ## What the last clean landing was worth, for the HUD.
var special: float = 0.0 ## The meter, 0 to [constant SPECIAL_FULL].
var special_lit: bool = false ## Full and lit: stats up three, special tricks open, until it drains away.
var _history: Dictionary = {} ## Trick name to times done in banked combos this run, for the depreciation.
var _combo_uses: Dictionary = {} ## Trick name to times done in this combo.
var _recent_special: int = 0 ## What of the combo's worth the meter has already been given (m_recentSpecialScorePot).


## The trick for [param table] (one of [constant FLIPS], [constant GRABS], [constant GRINDS], [constant LIPS])
## with [param direction] held ("", "left", "right", "up" or "down"), as [name, points].
static func named(table: Dictionary, direction: String) -> Array:
	return table.get(direction, table[""])


## The direction name THUG's d-pad would give for a stick reading ("up_left" and the other diagonals when both
## are held), or "" for centred.
static func direction_of(motion: Vector2) -> String:
	var vertical: String = "up" if motion.y > 0.0 else ("down" if motion.y < 0.0 else "")
	var horizontal: String = "left" if motion.x < 0.0 else ("right" if motion.x > 0.0 else "")
	if vertical != "" and horizontal != "":
		return vertical + "_" + horizontal
	return vertical + horizontal


## The extra a repeated press turns [param trick_name] into, as [name, points], or empty when it has none.
static func extra_for(trick_name: String) -> Array:
	return EXTRAS.get(trick_name, [])


## The double-tap trick for [param kind] ("flip" or "grind") after [param taps] (the last two directions tapped,
## oldest first), as [name, points], or empty.
static func double_tap(kind: String, taps: Array) -> Array:
	if taps.size() != 2 or not DOUBLE_TAPS.has(kind):
		return []
	return DOUBLE_TAPS[kind].get(",".join(PackedStringArray([str(taps[0]), str(taps[1])])), [])


## The grind for [param direction] held when a rail is taken, [param across] the travel or along it.
static func named_grind(direction: String, across: bool) -> Array:
	if across and ACROSS_GRINDS.has(direction):
		return ACROSS_GRINDS[direction]
	return named(GRINDS, direction)


## The spin a landing counts, in degrees, from the yaw turned in the air: to the nearest half turn, or the next one
## when within [constant SPIN_SLOP] of it (THUG's spin_count_slop); 0 for less than a half turn.
static func counted_spin(degrees_turned: float) -> int:
	var turned: float = absf(degrees_turned)
	var half_turns: int = int(floorf((turned + SPIN_SLOP) / 180.0))
	return half_turns * 180


## Whether a landing with [param degrees_turned] in the air is off enough from a half turn to be a bail: more than
## the slop past a half turn and less than the next one minus the slop.
static func spin_is_sloppy(degrees_turned: float) -> bool:
	var turned: float = fmod(absf(degrees_turned), 180.0)
	return turned > SPIN_SLOP and turned < 180.0 - SPIN_SLOP


## What a [param spin] of so many degrees multiplies its trick by (Score::spinMult).
static func spin_multiplier(spin: int) -> float:
	return SPIN_MULTIPLIERS[mini(spin / 180, SPIN_MULTIPLIERS.size() - 1)]


## The special trick a [param kind] ("flip", "grab" or "grind") button gives after [param taps] (the last two
## directions tapped, oldest first) with the meter lit, as [name, points], or empty for the plain trick.
func special_trick(kind: String, taps: Array) -> Array:
	if not special_lit or not SPECIALS.has(kind):
		return []
	var slot: Dictionary = SPECIALS[kind]
	return slot["trick"] if taps == slot["taps"] else []


## Adds [param name] worth [param points] to the combo, depreciated for every time it has been done before.
func add(name: String, points: int) -> void:
	var uses: int = int(_history.get(name, 0)) + int(_combo_uses.get(name, 0))
	_combo_uses[name] = int(_combo_uses.get(name, 0)) + 1
	combo.append({"name": name, "points": points, "spin": 0, "spin_text": "", "uses": uses})
	_feed_special()


## Turns the combo's last trick into [param name] worth [param points] (an extra: a Kickflip into a Double
## Kickflip), keeping its spin; the uses count moves to the new name.
func upgrade_last(name: String, points: int) -> void:
	if combo.is_empty():
		add(name, points)
		return
	var entry: Dictionary = combo.back()
	var old: String = entry["name"]
	_combo_uses[old] = maxi(int(_combo_uses.get(old, 0)) - 1, 0)
	entry["uses"] = int(_history.get(name, 0)) + int(_combo_uses.get(name, 0))
	_combo_uses[name] = int(_combo_uses.get(name, 0)) + 1
	entry["name"] = name
	entry["points"] = points
	_feed_special()


## Attaches the spin a landing counts to the trick of that air (the combo's last, when [param on_last]), or to an
## ollie added for it (THUG's "Ollie"), named the THPS way ("FS 360", frontside for a left spin; an ollie's odd
## half turns land fakie, so their side is swapped). Returns the spin's name, or "" for less than a half turn.
func add_spin(degrees_turned: float, on_last: bool = false) -> String:
	var spin: int = counted_spin(degrees_turned)
	if spin == 0:
		return ""
	var frontside: bool = degrees_turned > 0.0
	if not on_last or combo.is_empty():
		add(OLLIE[0], OLLIE[1])
		if (spin / 180) % 2 == 1:
			frontside = not frontside
	var text: String = ("FS " if frontside else "BS ") + str(spin)
	var entry: Dictionary = combo.back()
	entry["spin"] = spin
	entry["spin_text"] = text
	_feed_special()
	return text


## What [param entry] of the combo is worth: base times depreciation times spin (Score::get_packed_score).
static func entry_points(entry: Dictionary) -> int:
	var depreciation: int = DEPRECIATION[mini(int(entry["uses"]), DEPRECIATION.size() - 1)]
	return int(int(entry["points"]) * depreciation * spin_multiplier(int(entry["spin"])) / 100.0)


## The combo's base points, every trick's worth summed.
func combo_points() -> int:
	var total: int = 0
	for entry: Dictionary in combo:
		total += entry_points(entry)
	return total


## The combo's worth right now: base points times the number of tricks.
func combo_total() -> int:
	return combo_points() * combo.size()


## The names in the combo, in order, without their spins.
func names() -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in combo:
		out.append(entry["name"])
	return out


## A clean landing banks the combo; what was done in it counts against the next. Returns what it was worth.
func land_clean() -> int:
	last_banked = combo_total()
	score += last_banked
	for name: String in _combo_uses:
		_history[name] = int(_history.get(name, 0)) + int(_combo_uses[name])
	combo.clear()
	_combo_uses.clear()
	_recent_special = 0
	return last_banked


## A bail throws the combo away, and empties the special meter (Score::Bail).
func bail() -> void:
	combo.clear()
	_combo_uses.clear()
	_recent_special = 0
	special = 0.0
	special_lit = false


## Runs the meter's drain (Score::Update): slow while it fills, fast while lit; empty, it goes out.
func update(delta: float) -> void:
	if special <= 0.0:
		return
	special -= (SPECIAL_LIT_DRAIN if special_lit else SPECIAL_DRAIN) * delta
	if special <= 0.0:
		special = 0.0
		special_lit = false


## Where in each stat's range the board sits right now.
func stat() -> float:
	return SPECIAL_STAT if special_lit else STAT


## The HUD line: "FS 180 Kickflip + Manual" and "250 x 2".
func combo_text() -> String:
	var parts: Array[String] = []
	for entry: Dictionary in combo:
		parts.append((str(entry["spin_text"]) + " " + str(entry["name"])) if int(entry["spin"]) != 0 else str(entry["name"]))
	return " + ".join(parts)


func total_text() -> String:
	if combo.is_empty():
		return ""
	return "%s x %d" % [_with_commas(combo_points()), combo.size()]


## The meter is given what the combo has grown by since it last was (Score::Trigger with NewSpecial): it fills as
## the skater scores, not only on the landing.
func _feed_special() -> void:
	var worth: int = combo_total()
	if worth > _recent_special:
		special = minf(special + (worth - _recent_special), SPECIAL_FULL)
		if special >= SPECIAL_FULL:
			special_lit = true
	_recent_special = worth


static func _with_commas(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
