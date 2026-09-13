class_name Rail
extends Path3D
## Something the board can grind: a [Path3D] laid along the edge of a ledge, the top of a handrail or the
## back of a bench. The board looks for rails only while it is in the air with Grind held, the way THUG's
## skater does (CRailManager::StickToRail), snaps to the nearest one within [member Skateboard.RAIL_MAX_SNAP]
## with a strong preference for rails it is travelling along, and rides the curve until it ends or turns a
## corner sharper than [member leave_angle_degrees].

@export var speed_boost: float = 3.81 ## Rail_Speed_Boost, THUG's 150 in/s: metres per second added on locking on, so a grind never stalls at the start.
@export_range(0.0, 180.0) var leave_angle_degrees: float = 60.0 ## Rail_Corner_Leave_Angle: a bend sharper than this is the end of the rail.


func _ready() -> void:
	add_to_group("rails")


func length() -> float:
	return curve.get_baked_length() if curve else 0.0


## The world point [param offset] metres along the rail.
func point_at(offset: float) -> Vector3:
	return to_global(curve.sample_baked(clampf(offset, 0.0, length()), true))


## The world direction of the rail at [param offset], from the start toward the end.
func direction_at(offset: float) -> Vector3:
	var len: float = length()
	var a: Vector3 = to_global(curve.sample_baked(clampf(offset - 0.05, 0.0, len), true))
	var b: Vector3 = to_global(curve.sample_baked(clampf(offset + 0.05, 0.0, len), true))
	var direction: Vector3 = b - a
	return direction.normalized() if direction.length_squared() > 0.000001 else global_basis.x


## The closest the rail comes to the segment [param from] to [param to] (a frame of movement), as
## [code]{"distance", "offset", "point", "direction"}[/code], or empty when the rail has no curve. The segment is
## sampled at a few points, which is enough for the length of one physics frame.
func closest_to_segment(from: Vector3, to: Vector3) -> Dictionary:
	if curve == null or curve.point_count < 2:
		return {}
	var best: Dictionary = {}
	for i: int in 5:
		var sample: Vector3 = to_local(from.lerp(to, i / 4.0))
		var offset: float = curve.get_closest_offset(sample)
		var point: Vector3 = curve.sample_baked(offset, true)
		var distance: float = sample.distance_to(point)
		if best.is_empty() or distance < float(best["distance"]):
			best = {"distance": distance, "offset": offset, "point": to_global(point), "direction": direction_at(offset)}
	return best
