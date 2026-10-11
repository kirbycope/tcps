extends GutTest
## Purpose: the balance model behind manuals and grinds does what THUG's CManual does: left alone the needle
## runs away, faster the longer the trick lasts; pressing against the lean brings it back; pressing with it
## throws it off the end, which is the bail.


func test_the_needle_starts_centred_sets_off_the_way_the_kind_falls_and_runs_away_on_its_own() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup()
	assert_eq(balance.lean, 0.0, "A fresh trick starts with the needle in the middle (THUG's SetUp carries nothing in)")
	assert_almost_eq(balance.lean_dir, SkateBalance.REPEAT_MIN, 0.0001, "moving toward the tail of a manual at Repeat_Min")
	var nose: SkateBalance = SkateBalance.new()
	nose.setup("nose_manual")
	assert_almost_eq(nose.lean_dir, -SkateBalance.REPEAT_MIN, 0.0001, "and toward the nose of a nose manual")
	var bailed: bool = false
	var ticks: int = 0
	while not bailed and ticks < 600:
		bailed = balance.update(1.0 / 60.0, 0.0)
		ticks += 1
	assert_true(bailed, "Left alone the needle goes off the end")
	assert_gt(ticks, 30, "but not at once")
	assert_gt(balance.lean, 0.0, "the way it set off")


## Ten ticks with nothing held, so the needle is off the middle and there is a lean to press against.
func _leaning(balance: SkateBalance) -> float:
	for i: int in 10:
		balance.update(1.0 / 60.0, 0.0)
	return signf(balance.lean)


func test_pressing_against_the_lean_brings_the_needle_back() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup()
	var away: float = _leaning(balance)
	var start: float = absf(balance.lean)
	var bailed: bool = false
	for i: int in 15:
		bailed = balance.update(1.0 / 60.0, -away) or bailed
	assert_false(bailed, "A quarter second against the lean is not a bail")
	assert_lt(balance.lean * away, start, "and the needle came back toward the middle")


func test_pressing_with_the_lean_is_the_bail() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup()
	var away: float = _leaning(balance)
	var ticks: int = 0
	var bailed: bool = false
	while not bailed and ticks < 600:
		bailed = balance.update(1.0 / 60.0, away)
		ticks += 1
	assert_true(bailed, "Pushing the way it leans throws the needle off the end")
	assert_lt(ticks, 120, "quickly, once the safe period has let the button in")


func test_a_button_toward_the_lean_ramps_in_over_the_first_second() -> void:
	var fresh: SkateBalance = SkateBalance.new()
	fresh.setup()
	fresh.lean = 0.2
	fresh.lean_dir = 0.0
	fresh.update(1.0 / 60.0, 1.0)
	var late: SkateBalance = SkateBalance.new()
	late.setup()
	late.lean = 0.2
	late.lean_dir = 0.0
	late.actual_time = SkateBalance.SAFE_BUTTON_PERIOD
	late.update(1.0 / 60.0, 1.0)
	assert_lt(fresh.lean_dir, late.lean_dir * 0.1, "At the start a button pressed toward the lean barely counts (BalanceSafeButtonPeriod)")
	var against: SkateBalance = SkateBalance.new()
	against.setup()
	against.lean = 0.2
	against.lean_dir = 0.0
	against.update(1.0 / 60.0, -1.0)
	assert_almost_eq(against.lean_dir, -late.lean_dir, 0.0001, "while one pressed against it counts in full from the first tick")


func test_the_next_trick_of_the_combo_carries_the_lean_the_needle_and_the_time() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup("grind", 1)
	for i: int in 30:
		balance.update(1.0 / 60.0, 0.0)
	var lean: float = balance.lean
	var lean_dir: float = balance.lean_dir
	var time: float = balance.time
	assert_almost_eq(balance.cheese, 0.0, 0.001, "Half a second on a grind has spent its cheese (GrindParams' 30 frames)")
	balance.setup("grind", 2)
	assert_almost_eq(balance.lean, lean * SkateBalance.GRIND_LEAN_REPEAT_MULTIPLIER, 0.0001, "A new rail in the combo starts with the lean scaled by Lean_Repeat_Multiplier")
	assert_almost_eq(balance.lean_dir, maxf(absf(lean_dir) * SkateBalance.GRIND_REPEAT_MULTIPLIER, SkateBalance.REPEAT_MIN) * signf(lean_dir), 0.0001, "the needle's speed by Repeat_Multiplier")
	assert_almost_eq(balance.time, time + SkateBalance.NEW_GRIND_ADD_TIME, 0.0001, "and the time carried on, plus New_Grind_Sub_Time's little bit")
	assert_eq(balance.actual_time, 0.0, "though the trick's own clock is new")
	time = balance.time
	balance.setup("grind", 2)
	assert_almost_eq(balance.time, time + SkateBalance.SAME_GRIND_ADD_TIME, 0.0001, "Back on the rail just left is Same_Grind_Add_Time dearer")
	balance.reset()
	assert_eq([balance.lean, balance.lean_dir, balance.time, balance.cheese], [0.0, 0.0, 0.0, 0.0], "A clean landing or a bail forgets it all")


func test_a_grind_hopped_off_at_once_lands_its_cheese_on_the_next() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup("grind", 1)
	assert_almost_eq(balance.cheese, SkateBalance.GRIND_CHEESE, 0.0001, "A grind starts with a full helping of cheese")
	for i: int in 3:
		balance.update(1.0 / 60.0, 0.0)
	var unspent: float = balance.cheese
	assert_gt(unspent, SkateBalance.GRIND_CHEESE * 0.8, "three frames spend little of it")
	var lean: float = balance.lean
	balance.setup("grind", 1)
	assert_almost_eq(balance.lean, lean * SkateBalance.GRIND_LEAN_REPEAT_MULTIPLIER + unspent * signf(lean), 0.0001, "and the next grind starts with it added to the lean")
	assert_gt(absf(balance.lean), 0.4, "most of the way to the edge: a combo of grinds a few frames long each does not pay")
	balance.setup("grind", 3)
	assert_almost_eq(balance.cheese, SkateBalance.GRIND_CHEESE, 0.0001, "A different rail clears the cheese before the helping (it is not cheesy to change rails)")


func test_the_trick_gets_harder_the_longer_it_lasts() -> void:
	seed(7)
	var early: SkateBalance = SkateBalance.new()
	early.setup()
	early.lean = 0.2
	early.lean_dir = 0.0
	early.update(1.0 / 60.0, 0.0)
	var late: SkateBalance = SkateBalance.new()
	late.setup()
	late.lean = 0.2
	late.lean_dir = 0.0
	late.time = 10.0
	late.update(1.0 / 60.0, 0.0)
	assert_gt(late.lean - 0.2, early.lean - 0.2, "The same lean grows faster ten seconds in")


func test_the_meter_draws_the_lean() -> void:
	var meter: BalanceMeter = BalanceMeter.new()
	meter.size = Vector2(240.0, 24.0)
	add_child_autofree(meter)
	meter.lean = 2.0
	assert_eq(meter.lean, 1.0, "The meter clamps to its ends")
	meter.lean = -0.5
	assert_eq(meter.lean, -0.5)
