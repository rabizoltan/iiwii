extends RefCounted

const EnemyDebugSnapshot = preload("res://scripts/enemy/debug/enemy_debug_snapshot.gd")


class BuildRequest:
	extends RefCounted

	var current_path: PackedVector3Array = PackedVector3Array()
	var has_goal: bool = false
	var current_goal_position: Vector3 = Vector3.ZERO
	var debug_candidate_positions: PackedVector3Array = PackedVector3Array()


static func build(request: BuildRequest) -> EnemyDebugSnapshot:
	var snapshot: EnemyDebugSnapshot = EnemyDebugSnapshot.new()
	snapshot.current_path = request.current_path
	snapshot.has_goal = request.has_goal
	snapshot.current_goal_position = request.current_goal_position
	snapshot.debug_candidate_positions = request.debug_candidate_positions
	return snapshot
