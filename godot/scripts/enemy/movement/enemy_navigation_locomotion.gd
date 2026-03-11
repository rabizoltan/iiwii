extends RefCounted


class NavigationCacheRequest:
	extends RefCounted

	var cached_nav_move_target: Vector3 = Vector3.ZERO
	var invalid_point: Vector3 = Vector3.ZERO
	var nav_refresh_remaining: float = 0.0
	var move_target: Vector3 = Vector3.ZERO
	var recovery_elapsed: float = 0.0
	var melee_state: int = -1
	var approach_state: int = -1
	var distance_to_target: float = 0.0
	var nav_refresh_far_distance: float = 0.0


class NavRefreshIntervalRequest:
	extends RefCounted

	var melee_state: int = -1
	var close_adjust_state: int = -1
	var close_adjust_nav_refresh_interval: float = 0.0
	var distance_to_target: float = 0.0
	var nav_refresh_far_distance: float = 0.0
	var nav_refresh_interval_near: float = 0.0
	var nav_refresh_interval_far: float = 0.0


class ApproachVelocityResult:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var attempted_move: bool = false
	var state_suffix: String = "at_next"
	var move_direction: Vector3 = Vector3.ZERO
	var recovery_elapsed: float = 0.0


static func should_refresh_navigation_cache(request: NavigationCacheRequest) -> bool:
	if request.cached_nav_move_target == request.invalid_point:
		return true

	if request.nav_refresh_remaining <= 0.0:
		return true

	if _horizontal_distance(request.cached_nav_move_target, request.move_target) > 0.05:
		return true

	if request.recovery_elapsed > 0.0:
		return true

	if request.melee_state == request.approach_state and request.distance_to_target <= request.nav_refresh_far_distance:
		return true

	return false


static func compute_nav_refresh_interval(request: NavRefreshIntervalRequest) -> float:
	if request.melee_state == request.close_adjust_state:
		return maxf(request.close_adjust_nav_refresh_interval, 0.0)

	if request.distance_to_target <= request.nav_refresh_far_distance:
		return request.nav_refresh_interval_near

	return request.nav_refresh_interval_far


static func resolve_navigation_next_position(
	nav_agent: NavigationAgent3D,
	global_position: Vector3,
	move_target: Vector3
) -> Vector3:
	var next_position := nav_agent.get_next_path_position()
	var horizontal_offset := next_position - global_position
	horizontal_offset.y = 0.0
	if horizontal_offset.length_squared() > 0.04:
		return next_position

	var path := nav_agent.get_current_navigation_path()
	for path_point in path:
		var path_offset := path_point - global_position
		path_offset.y = 0.0
		if path_offset.length_squared() > 0.04:
			return path_point

	return move_target


static func compute_approach_velocity(
	global_position: Vector3,
	next_position: Vector3,
	recovery_elapsed: float,
	recovery_sign: float,
	move_speed: float
) -> ApproachVelocityResult:
	var horizontal_offset := next_position - global_position
	horizontal_offset.y = 0.0
	if horizontal_offset.length_squared() <= 0.04:
		var idle_result: ApproachVelocityResult = ApproachVelocityResult.new()
		idle_result.recovery_elapsed = recovery_elapsed
		return idle_result

	var move_direction := horizontal_offset.normalized()
	var state_suffix := "moving"
	var next_recovery_elapsed := recovery_elapsed
	if next_recovery_elapsed > 0.0:
		var recovery_tangent := Vector3(-move_direction.z, 0.0, move_direction.x) * recovery_sign
		move_direction = (move_direction * 0.25 + recovery_tangent).normalized()
		next_recovery_elapsed = maxf(next_recovery_elapsed, 0.0)
		state_suffix = "recovering"

	var result: ApproachVelocityResult = ApproachVelocityResult.new()
	result.velocity = move_direction * move_speed
	result.attempted_move = true
	result.state_suffix = state_suffix
	result.move_direction = move_direction
	result.recovery_elapsed = next_recovery_elapsed
	return result


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()
