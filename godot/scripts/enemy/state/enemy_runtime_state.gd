extends RefCounted


class GoalDebugState:
	extends RefCounted

	var candidate_positions: PackedVector3Array = PackedVector3Array()
	var candidate_count: int = 0
	var rejected_projection_count: int = 0
	var rejected_failed_count: int = 0
	var unreachable_path_count: int = 0
	var used_fallback: bool = false
	var raw_candidate: Vector3 = Vector3.ZERO
	var projected_candidate: Vector3 = Vector3.ZERO
	var projection_error: float = 0.0
	var selected_path_length: float = INF
	var path_end: Vector3 = Vector3.ZERO
	var path_end_error: float = 0.0

	func reset() -> void:
		candidate_positions = PackedVector3Array()
		candidate_count = 0
		rejected_projection_count = 0
		rejected_failed_count = 0
		unreachable_path_count = 0
		used_fallback = false
		raw_candidate = Vector3.ZERO
		projected_candidate = Vector3.ZERO
		projection_error = 0.0
		selected_path_length = INF
		path_end = Vector3.ZERO
		path_end_error = 0.0


class CloseAdjustDebugState:
	extends RefCounted

	var nav_cache_refreshed: bool = false
	var path_distance: float = 0.0
	var target_gap: float = 0.0
	var crowd_pressure: float = 0.0
	var left_penalty: float = 0.0
	var right_penalty: float = 0.0
	var side_sign: float = 0.0
	var lateral_weight: float = 0.0
	var move_speed: float = 0.0

	func reset() -> void:
		nav_cache_refreshed = false
		path_distance = 0.0
		target_gap = 0.0
		crowd_pressure = 0.0
		left_penalty = 0.0
		right_penalty = 0.0
		side_sign = 0.0
		lateral_weight = 0.0
		move_speed = 0.0


class YieldDebugState:
	extends RefCounted

	var speed: float = 0.0
	var strength: float = 0.0
	var neighbor_count: int = 0
	var penalty: float = 0.0
	var direction: Vector3 = Vector3.ZERO
	var crowd_pressure: float = 0.0
	var direct_pressure: float = 0.0
	var chain_pressure: float = 0.0

	func reset() -> void:
		speed = 0.0
		strength = 0.0
		neighbor_count = 0
		penalty = 0.0
		direction = Vector3.ZERO
		crowd_pressure = 0.0
		direct_pressure = 0.0
		chain_pressure = 0.0


class HoldDebugState:
	extends RefCounted

	var displacement: float = 0.0
	var velocity: float = 0.0
	var collision_count: int = 0
	var collision_names: Array[String] = []
	var has_yield: bool = false

	func reset() -> void:
		displacement = 0.0
		velocity = 0.0
		collision_count = 0
		collision_names.clear()
		has_yield = false


class MovementInfluenceState:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var kind: String = ""

	func reset() -> void:
		velocity = Vector3.ZERO
		kind = ""

	func is_empty() -> bool:
		return kind.is_empty() and velocity.length_squared() <= 0.0001
