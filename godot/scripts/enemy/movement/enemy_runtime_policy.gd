extends RefCounted

const EnemyNavigationLocomotion = preload("res://scripts/enemy/movement/enemy_navigation_locomotion.gd")


class GoalRuntimeState:
	extends RefCounted

	var has_goal: bool = false
	var current_goal_position: Vector3 = Vector3.ZERO
	var goal_center_at_selection: Vector3 = Vector3.ZERO
	var goal_commit_remaining: float = 0.0
	var goal_select_cooldown_remaining: float = 0.0
	var recent_failed_goals: Array[Vector3] = []


class NavigationCacheState:
	extends RefCounted

	var nav_refresh_remaining: float = 0.0
	var cached_nav_next_position: Vector3 = Vector3.ZERO
	var cached_nav_move_target: Vector3 = Vector3.ZERO


class GoalRefreshRequest:
	extends RefCounted

	var has_valid_target: bool = false
	var has_goal: bool = false
	var goal_select_cooldown_remaining: float = 0.0
	var goal_commit_remaining: float = 0.0
	var goal_center_at_selection: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	var goal_reacquire_distance: float = 0.0
	var global_position: Vector3 = Vector3.ZERO
	var current_goal_position: Vector3 = Vector3.ZERO
	var engage_hold_tolerance: float = 0.0


class ApplyGoalSelectionRequest:
	extends RefCounted

	var goal_position: Vector3 = Vector3.ZERO
	var goal_center: Vector3 = Vector3.ZERO
	var goal_commit_duration: float = 0.0
	var invalid_point: Vector3 = Vector3.ZERO


class GoalMemoryRequest:
	extends RefCounted

	var goal_position: Vector3 = Vector3.ZERO
	var failed_goal_memory_count: int = 0


class GoalCooldownRequest:
	extends RefCounted

	var goal_select_min_interval: float = 0.0


class NavigationNextPositionRequest:
	extends RefCounted

	var cache_state: NavigationCacheState
	var move_target: Vector3 = Vector3.ZERO
	var invalid_point: Vector3 = Vector3.ZERO
	var recovery_elapsed: float = 0.0
	var melee_state: int = -1
	var approach_state: int = -1
	var distance_to_target: float = 0.0
	var nav_refresh_far_distance: float = 0.0
	var close_adjust_state: int = -1
	var close_adjust_nav_refresh_interval: float = 0.0
	var nav_refresh_interval_near: float = 0.0
	var nav_refresh_interval_far: float = 0.0
	var resolve_next_position: Callable


static func tick_goal_runtime(state: GoalRuntimeState, delta: float) -> void:
	if state.goal_commit_remaining > 0.0:
		state.goal_commit_remaining = maxf(state.goal_commit_remaining - delta, 0.0)

	if state.goal_select_cooldown_remaining > 0.0:
		state.goal_select_cooldown_remaining = maxf(state.goal_select_cooldown_remaining - delta, 0.0)


static func tick_navigation_cache(state: NavigationCacheState, delta: float) -> void:
	if state.nav_refresh_remaining > 0.0:
		state.nav_refresh_remaining = maxf(state.nav_refresh_remaining - delta, 0.0)


static func should_refresh_goal(request: GoalRefreshRequest) -> bool:
	if not request.has_valid_target:
		return false
	if request.goal_select_cooldown_remaining > 0.0:
		return false
	if not request.has_goal:
		return true
	if request.goal_commit_remaining > 0.0:
		return false

	var target_shift := _horizontal_distance(request.goal_center_at_selection, request.target_position)
	if target_shift >= request.goal_reacquire_distance:
		return true

	var goal_distance := _horizontal_distance(request.global_position, request.current_goal_position)
	return goal_distance <= maxf(request.engage_hold_tolerance, 0.25)


static func apply_goal_selection(state: GoalRuntimeState, nav_state: NavigationCacheState, request: ApplyGoalSelectionRequest) -> void:
	state.current_goal_position = request.goal_position
	state.goal_center_at_selection = request.goal_center
	state.goal_commit_remaining = request.goal_commit_duration
	state.has_goal = true
	invalidate_navigation_cache(nav_state, request.invalid_point)


static func reset_goal_select_cooldown(state: GoalRuntimeState, request: GoalCooldownRequest) -> void:
	state.goal_select_cooldown_remaining = maxf(request.goal_select_min_interval, 0.0)


static func remember_failed_goal(state: GoalRuntimeState, request: GoalMemoryRequest) -> void:
	if request.failed_goal_memory_count <= 0:
		state.recent_failed_goals.clear()
		return

	state.recent_failed_goals.append(request.goal_position)
	while state.recent_failed_goals.size() > request.failed_goal_memory_count:
		state.recent_failed_goals.remove_at(0)


static func clear_goal_navigation_state(
	state: GoalRuntimeState,
	nav_state: NavigationCacheState,
	nav_agent: NavigationAgent3D,
	global_position: Vector3,
	invalid_point: Vector3
) -> void:
	state.has_goal = false
	state.goal_commit_remaining = 0.0
	nav_agent.target_position = global_position
	invalidate_navigation_cache(nav_state, invalid_point)


static func invalidate_navigation_cache(state: NavigationCacheState, invalid_point: Vector3) -> void:
	state.nav_refresh_remaining = 0.0
	state.cached_nav_next_position = Vector3.ZERO
	state.cached_nav_move_target = invalid_point


static func get_navigation_next_position(request: NavigationNextPositionRequest) -> Vector3:
	if _should_refresh_navigation_cache(request):
		request.cache_state.cached_nav_move_target = request.move_target
		request.cache_state.nav_refresh_remaining = _compute_nav_refresh_interval(request)

	request.cache_state.cached_nav_next_position = request.resolve_next_position.call(request.move_target)
	return request.cache_state.cached_nav_next_position


static func _should_refresh_navigation_cache(request: NavigationNextPositionRequest) -> bool:
	var nav_request := EnemyNavigationLocomotion.NavigationCacheRequest.new()
	nav_request.cached_nav_move_target = request.cache_state.cached_nav_move_target
	nav_request.invalid_point = request.invalid_point
	nav_request.nav_refresh_remaining = request.cache_state.nav_refresh_remaining
	nav_request.move_target = request.move_target
	nav_request.recovery_elapsed = request.recovery_elapsed
	nav_request.melee_state = request.melee_state
	nav_request.approach_state = request.approach_state
	nav_request.distance_to_target = request.distance_to_target
	nav_request.nav_refresh_far_distance = request.nav_refresh_far_distance
	return EnemyNavigationLocomotion.should_refresh_navigation_cache(nav_request)


static func _compute_nav_refresh_interval(request: NavigationNextPositionRequest) -> float:
	var interval_request := EnemyNavigationLocomotion.NavRefreshIntervalRequest.new()
	interval_request.melee_state = request.melee_state
	interval_request.close_adjust_state = request.close_adjust_state
	interval_request.close_adjust_nav_refresh_interval = request.close_adjust_nav_refresh_interval
	interval_request.distance_to_target = request.distance_to_target
	interval_request.nav_refresh_far_distance = request.nav_refresh_far_distance
	interval_request.nav_refresh_interval_near = request.nav_refresh_interval_near
	interval_request.nav_refresh_interval_far = request.nav_refresh_interval_far
	return EnemyNavigationLocomotion.compute_nav_refresh_interval(interval_request)


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()

