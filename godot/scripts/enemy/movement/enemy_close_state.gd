extends RefCounted

const APPROACH := 0
const CLOSE_ADJUST := 1
const MELEE_HOLD := 2


static func is_in_melee_hold(
	global_position: Vector3,
	target_position: Vector3,
	melee_engage_distance: float,
	engage_hold_tolerance: float,
	engage_vertical_tolerance: float
) -> bool:
	var vertical_offset := absf(target_position.y - global_position.y)
	if vertical_offset > engage_vertical_tolerance:
		return false

	return _horizontal_distance(global_position, target_position) <= melee_engage_distance + engage_hold_tolerance


static func is_in_close_adjust_band(
	global_position: Vector3,
	target_position: Vector3,
	close_adjust_enter_distance: float,
	melee_engage_distance: float,
	engage_hold_tolerance: float,
	engage_vertical_tolerance: float
) -> bool:
	var vertical_offset := absf(target_position.y - global_position.y)
	if vertical_offset > engage_vertical_tolerance:
		return false

	return _horizontal_distance(global_position, target_position) <= maxf(
		close_adjust_enter_distance,
		melee_engage_distance + engage_hold_tolerance
	)


static func compute_next_state(
	global_position: Vector3,
	target_position: Vector3,
	close_adjust_enter_distance: float,
	melee_engage_distance: float,
	engage_hold_tolerance: float,
	engage_vertical_tolerance: float
) -> int:
	if is_in_melee_hold(
		global_position,
		target_position,
		melee_engage_distance,
		engage_hold_tolerance,
		engage_vertical_tolerance
	):
		return MELEE_HOLD

	if is_in_close_adjust_band(
		global_position,
		target_position,
		close_adjust_enter_distance,
		melee_engage_distance,
		engage_hold_tolerance,
		engage_vertical_tolerance
	):
		return CLOSE_ADJUST

	return APPROACH


static func get_state_name(state: int) -> String:
	match state:
		APPROACH:
			return "approach"
		CLOSE_ADJUST:
			return "close_adjust"
		MELEE_HOLD:
			return "melee_hold"

	return "unknown"


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()
