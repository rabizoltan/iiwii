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


class StateDispatchRequest:
	extends RefCounted

	var current_state: int = EnemyCloseState.APPROACH
	var should_refresh_goal: Callable
	var select_engage_goal: Callable
	var reset_goal_select_cooldown: Callable
	var run_approach_state: Callable
	var run_close_adjust_state: Callable
	var run_melee_hold_state: Callable
	var fallback_next_position: Vector3 = Vector3.ZERO
	var fallback_face_position: Vector3 = Vector3.ZERO


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


static func dispatch_state(request: StateDispatchRequest) -> StateDispatchResult:
	var current_state: int = request.current_state

	match current_state:
		EnemyCloseState.APPROACH:
			if request.should_refresh_goal.call():
				request.select_engage_goal.call()
				request.reset_goal_select_cooldown.call()
			return request.run_approach_state.call()
		EnemyCloseState.CLOSE_ADJUST:
			return request.run_close_adjust_state.call()
		EnemyCloseState.MELEE_HOLD:
			return request.run_melee_hold_state.call()

	var result: StateDispatchResult = StateDispatchResult.new()
	result.state = EnemyCloseState.get_state_name(current_state)
	result.next_position = request.fallback_next_position
	result.face_position = request.fallback_face_position
	return result
