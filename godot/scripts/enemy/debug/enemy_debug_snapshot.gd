extends RefCounted


var current_path: PackedVector3Array = PackedVector3Array()
var has_goal: bool = false
var current_goal_position: Vector3 = Vector3.ZERO
var debug_candidate_positions: PackedVector3Array = PackedVector3Array()
