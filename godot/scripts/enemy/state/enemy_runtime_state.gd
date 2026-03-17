extends RefCounted


class GoalDebugState:
	extends RefCounted

	var candidate_positions: PackedVector3Array = PackedVector3Array()

	func reset() -> void:
		candidate_positions = PackedVector3Array()


class MovementInfluenceState:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var kind: String = ""

	func reset() -> void:
		velocity = Vector3.ZERO
		kind = ""

	func is_empty() -> bool:
		return kind.is_empty() and velocity.length_squared() <= 0.0001
