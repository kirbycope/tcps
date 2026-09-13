extends GutTest
## Purpose: the balance model behind manuals and grinds does what THUG's CManual does: left alone the needle
## runs away, faster the longer the trick lasts; pressing against the lean brings it back; pressing with it
## throws it off the end, which is the bail.


func test_the_needle_starts_off_centre_and_runs_away_on_its_own() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup()
	assert_ne(balance.lean, 0.0, "The trick starts with the needle off centre")
	assert_lt(absf(balance.lean), SkateBalance.START_RANGE + 0.001, "but only a little")
	assert_eq(signf(balance.lean_dir), signf(balance.lean), "and already moving away from the middle")
	var start: float = absf(balance.lean)
	var bailed: bool = false
	var ticks: int = 0
	while not bailed and ticks < 600:
		bailed = balance.update(1.0 / 60.0, 0.0)
		ticks += 1
	assert_true(bailed, "Left alone the needle goes off the end")
	assert_gt(ticks, 30, "but not at once")
	assert_gt(absf(balance.lean), start, "having grown the whole way")


func test_pressing_against_the_lean_brings_the_needle_back() -> void:
	seed(7)
	var balance: SkateBalance = SkateBalance.new()
	balance.setup()
	var away: float = signf(balance.lean)
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
	var away: float = signf(balance.lean)
	var ticks: int = 0
	var bailed: bool = false
	while not bailed and ticks < 600:
		bailed = balance.update(1.0 / 60.0, away)
		ticks += 1
	assert_true(bailed, "Pushing the way it leans throws the needle off the end")
	assert_lt(ticks, 90, "quickly")


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
