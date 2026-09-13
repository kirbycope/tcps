class_name BalanceMeter
extends Control
## The balance meter under the skater during a manual or a grind: a bar with a centre mark and a needle that
## shows [member lean], which the board sets from its [SkateBalance] every tick. Red at either end is the bail.

const TRACK_COLOR: Color = Color(0.1, 0.1, 0.1, 0.7)
const MARK_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const NEEDLE_COLOR: Color = Color(1.0, 0.9, 0.2)
const DANGER_COLOR: Color = Color(1.0, 0.25, 0.2)

var lean: float = 0.0: ## -1 to 1, from [member SkateBalance.lean].
	set(value):
		lean = clampf(value, -1.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var track: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(track, TRACK_COLOR)
	draw_rect(track, MARK_COLOR, false, 1.0)
	var centre: float = size.x * 0.5
	draw_line(Vector2(centre, 0.0), Vector2(centre, size.y), MARK_COLOR, 2.0)
	var needle_x: float = centre + lean * (size.x * 0.5 - 4.0)
	var color: Color = DANGER_COLOR if absf(lean) > 0.75 else NEEDLE_COLOR
	draw_rect(Rect2(needle_x - 4.0, 1.0, 8.0, size.y - 2.0), color)
