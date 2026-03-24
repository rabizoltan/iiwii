extends RefCounted


class MovementInfluenceState:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var kind: String = ""

	func reset() -> void:
		velocity = Vector3.ZERO
		kind = ""

	func is_empty() -> bool:
		return kind.is_empty() and velocity.length_squared() <= 0.0001
