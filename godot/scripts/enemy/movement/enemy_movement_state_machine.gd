extends RefCounted

const EnemyCloseState = preload("res://scripts/enemy/movement/enemy_close_state.gd")


class TransitionRequest:
	extends RefCounted

	var global_position: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	var close_adjust_enter_distance: float = 0.0
	var melee_engage_distance: float = 0.0
	var engage_hold_tolerance: float = 0.0
	var engage_vertical_tolerance: float = 0.0



class StateDispatchResult:
	extends RefCounted

	var state: String = "idle"
	var next_position: Vector3 = Vector3.ZERO
	var attempted_move: bool = false
	var move_velocity: Vector3 = Vector3.ZERO
	var face_position: Vector3 = Vector3.ZERO


static func compute_next_state(request: TransitionRequest) -> int:
	return EnemyCloseState.compute_next_state(
		request.global_position,
		request.target_position,
		request.close_adjust_enter_distance,
		request.melee_engage_distance,
		request.engage_hold_tolerance,
		request.engage_vertical_tolerance
	)

