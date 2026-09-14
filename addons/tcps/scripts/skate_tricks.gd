class_name SkateTricks
extends RefCounted
## The trick layer and the score, after THUG's trick and score components (CTrickComponent, CSkaterScoreComponent):
## which trick a button and a direction name, what each is worth, and the combo they add up to. A combo is every
## trick since the last clean landing; its points are summed and multiplied by the number of tricks in it, banked
## into [member score] when the skater lands clean, and lost in a bail. Grinds, manuals and reverts are the links
## that carry a combo across a landing.

const FLIPS: Dictionary = { ## Square in THUG. Direction held at the press, then the name and the points.
	"": ["Kickflip", 100],
	"left": ["Heelflip", 100],
	"right": ["Pop Shove-It", 100],
	"up": ["Impossible", 150],
	"down": ["Hardflip", 150],
}
const GRABS: Dictionary = { ## Circle in THUG.
	"": ["Melon", 100],
	"left": ["Indy", 100],
	"right": ["Stalefish", 150],
	"up": ["Nosegrab", 100],
	"down": ["Tailgrab", 100],
}
const GRINDS: Dictionary = { ## Triangle in THUG, by the direction held when the rail is taken.
	"": ["50-50", 100],
	"left": ["Boardslide", 150],
	"right": ["Lipslide", 200],
	"up": ["Nosegrind", 150],
	"down": ["5-0", 150],
}
const MANUALS: Dictionary = {"manual": ["Manual", 100], "nose_manual": ["Nose Manual", 100]}
const LIPS: Dictionary = { ## Grind at the lip of a vert wall on the way up, by the direction held.
	"": ["Axle Stall", 250],
	"left": ["Disaster", 250],
	"right": ["Blunt To Fakie", 250],
	"up": ["Rock To Fakie", 200],
	"down": ["Nose Stall", 200],
}
const WALLRIDE: Array = ["Wallride", 250] ## Points for these are THPS-era values; THUG keeps its trick scores in scripts not in the repository.
const WALLPLANT: Array = ["Wallplant", 400]
const SPINE_TRANSFER: Array = ["Spine Transfer", 750]
const HIP_TRANSFER: Array = ["Hip Transfer", 500]
const ACID_DROP: Array = ["Acid Drop", 500]
const SPIN_POINTS: Dictionary = {180: 100, 360: 250, 540: 500, 720: 1000, 900: 2000} ## Beyond 900 the last entry stands.
const SPIN_SLOP: float = 60.0 ## spin_count_slop: a landing this far short of the next half turn still counts it.
const REVERT_POINTS: int = 25
const HOLD_POINTS_PER_SECOND: int = 200 ## What a grind, a manual or a held grab earns per second on top of its base.
const FLIP_TIME: float = 0.45 ## Seconds a flip trick takes; landing before it is done is a bail.
const GRAB_MIN_TIME: float = 0.25 ## A grab shorter than this is not one.

var score: int = 0 ## Points banked by clean landings.
var combo: Array[String] = [] ## The tricks since the last clean landing, in order, as shown on the HUD.
var combo_points: int = 0 ## Their base points summed.
var last_banked: int = 0 ## What the last clean landing was worth, for the HUD.


## The trick for [param table] (one of [constant FLIPS], [constant GRABS], [constant GRINDS]) with [param direction]
## held ("", "left", "right", "up" or "down"), as [name, points].
static func named(table: Dictionary, direction: String) -> Array:
	return table.get(direction, table[""])


## The direction name THUG's d-pad would give for a stick reading, or "" for centred.
static func direction_of(motion: Vector2) -> String:
	if absf(motion.x) > absf(motion.y):
		return "left" if motion.x < 0.0 else "right"
	if motion.y > 0.0:
		return "up"
	if motion.y < 0.0:
		return "down"
	return ""


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


## Adds [param name] worth [param points] to the combo.
func add(name: String, points: int) -> void:
	combo.append(name)
	combo_points += points


## Adds the spin a landing counts, named the THPS way ("FS 360", frontside for a left spin), or nothing for less
## than a half turn. Returns the name added, or "".
func add_spin(degrees_turned: float) -> String:
	var spin: int = counted_spin(degrees_turned)
	if spin == 0:
		return ""
	var name: String = ("FS " if degrees_turned > 0.0 else "BS ") + str(spin)
	add(name, SPIN_POINTS.get(spin, SPIN_POINTS[900]))
	return name


## Adds points to the last trick for time held on it (a grind, a manual, a held grab).
func hold(delta: float) -> void:
	if not combo.is_empty():
		combo_points += int(HOLD_POINTS_PER_SECOND * delta)


## The combo's worth right now: base points times the number of tricks.
func combo_total() -> int:
	return combo_points * combo.size()


## A clean landing banks the combo. Returns what it was worth.
func land_clean() -> int:
	last_banked = combo_total()
	score += last_banked
	combo.clear()
	combo_points = 0
	return last_banked


## A bail throws the combo away.
func bail() -> void:
	combo.clear()
	combo_points = 0


## The HUD line: "Kickflip + FS 180 + Manual" and "1,250 x 3".
func combo_text() -> String:
	return " + ".join(combo)


func total_text() -> String:
	if combo.is_empty():
		return ""
	return "%s x %d" % [_with_commas(combo_points), combo.size()]


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
