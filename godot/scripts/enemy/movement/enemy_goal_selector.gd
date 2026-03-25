extends RefCounted


class SelectGoalRequest:
	extends RefCounted

	var target_position: Vector3 = Vector3.ZERO
	var global_position: Vector3 = Vector3.ZERO
	var melee_engage_distance: float = 0.0
	var engage_candidate_count: int = 0
	var nearby_enemy_positions: Array[Vector3] = []
	var navigation_map: RID = RID()
	var navigation_layers: int = 0
	var candidate_projection_tolerance: float = 0.0
	var recent_failed_goals: Array[Vector3] = []
	var failed_goal_exclusion_radius: float = 0.0
	var spread_penalty_radius: float = 0.0
	var spread_penalty_weight: float = 0.0
	var goal_path_tiebreak_candidate_count: int = 0
	var goal_path_tiebreak_score_window: float = 0.0
	var goal_path_tiebreak_enemy_count_soft_limit: int = 0
	var goal_path_tiebreak_max_target_distance: float = 0.0
	var goal_path_endpoint_tolerance: float = 0.0
	var enemy_count: int = 0
	var distance_to_target: float = 0.0
	var direct_chase_distance: float = 0.0
	var invalid_point: Vector3 = Vector3.ZERO


class GoalDebugInfo:
	extends RefCounted

	var candidate_count: int = 0
	var rejected_projection_count: int = 0
	var rejected_failed_count: int = 0
	var unreachable_path_count: int = 0
	var used_fallback: bool = false
	var raw_candidate: Vector3 = Vector3.ZERO
	var projected_candidate: Vector3 = Vector3.ZERO
	var projection_error: float = 0.0
	var selected_path_length: float = INF


class CandidatePathMetrics:
	extends RefCounted

	var length: float = INF
	var end_error: float = INF


class GoalSelectionResult:
	extends RefCounted

	var has_goal: bool = false
	var goal_position: Vector3 = Vector3.ZERO
	var goal_center: Vector3 = Vector3.ZERO
	var debug: GoalDebugInfo = GoalDebugInfo.new()


static func select_engage_goal(request: SelectGoalRequest) -> GoalSelectionResult:
	if request.distance_to_target > request.direct_chase_distance:
		return _select_direct_chase_goal(request)

	var center := request.target_position
	var candidate_infos: Array[Dictionary] = []
	var best_score := INF
	var best_candidate := Vector3.ZERO
	var base_direction: Vector3 = request.global_position - center
	base_direction.y = 0.0
	if base_direction.length_squared() == 0.0:
		base_direction = Vector3.FORWARD

	var base_angle := atan2(base_direction.z, base_direction.x)
	var candidate_count := maxi(request.engage_candidate_count, 4)
	var debug_info: GoalDebugInfo = GoalDebugInfo.new()
	debug_info.candidate_count = candidate_count

	for candidate_index in range(candidate_count):
		var angle := base_angle + (TAU * float(candidate_index) / float(candidate_count))
		var raw_candidate: Vector3 = center + Vector3(cos(angle), 0.0, sin(angle)) * request.melee_engage_distance
		var projected_candidate: Vector3 = _project_candidate_to_nav(
			raw_candidate,
			request.navigation_map,
			request.candidate_projection_tolerance,
			request.invalid_point
		)
		if projected_candidate == request.invalid_point:
			debug_info.rejected_projection_count += 1
			continue

		if _is_failed_goal_candidate(
			projected_candidate,
			request.recent_failed_goals,
			request.failed_goal_exclusion_radius
		):
			debug_info.rejected_failed_count += 1
			continue

		var spread_score := _score_spread_penalty(
			projected_candidate,
			request.nearby_enemy_positions,
			request.spread_penalty_radius,
			request.spread_penalty_weight
		)
		var score: float = _horizontal_distance(request.global_position, projected_candidate) + spread_score
		candidate_infos.append({
			"raw_candidate": raw_candidate,
			"projected_candidate": projected_candidate,
			"spread_score": spread_score,
			"cheap_score": score,
		})
		if score < best_score:
			best_score = score

	if best_score == INF:
		var fallback_candidate: Vector3 = _project_candidate_to_nav(
			center,
			request.navigation_map,
			request.candidate_projection_tolerance,
			request.invalid_point
		)
		if fallback_candidate == request.invalid_point:
			var empty_result: GoalSelectionResult = GoalSelectionResult.new()
			empty_result.debug = debug_info
			return empty_result

		debug_info.used_fallback = true
		debug_info.raw_candidate = center
		debug_info.projected_candidate = fallback_candidate
		debug_info.projection_error = center.distance_to(fallback_candidate)
		var fallback_path_metrics := measure_candidate_path_metrics(
			request.navigation_map,
			request.global_position,
			fallback_candidate,
			request.navigation_layers
		)
		debug_info.selected_path_length = fallback_path_metrics.length
		if is_inf(debug_info.selected_path_length) or fallback_path_metrics.end_error > request.goal_path_endpoint_tolerance:
			var empty_result: GoalSelectionResult = GoalSelectionResult.new()
			empty_result.debug = debug_info
			return empty_result

		best_candidate = fallback_candidate
	else:
		var selected_candidate_info: Dictionary = _select_candidate_with_path_tiebreak(request, candidate_infos, best_score)
		debug_info.unreachable_path_count = int(selected_candidate_info.get("unreachable_path_count", 0))
		if not selected_candidate_info.has("projected_candidate"):
			var empty_result: GoalSelectionResult = GoalSelectionResult.new()
			empty_result.debug = debug_info
			return empty_result

		debug_info.raw_candidate = selected_candidate_info["raw_candidate"]
		debug_info.projected_candidate = selected_candidate_info["projected_candidate"]
		debug_info.projection_error = _horizontal_distance(
			debug_info.raw_candidate,
			debug_info.projected_candidate
		)
		debug_info.selected_path_length = float(selected_candidate_info.get("path_length", INF))
		best_candidate = debug_info.projected_candidate

	var result: GoalSelectionResult = GoalSelectionResult.new()
	result.has_goal = true
	result.goal_position = best_candidate
	result.goal_center = center
	result.debug = debug_info
	return result


static func should_use_path_tiebreak(
	candidate_count: int,
	has_valid_target: bool,
	enemy_count: int,
	distance_to_target: float,
	enemy_count_soft_limit: int,
	max_target_distance: float
) -> bool:
	if candidate_count <= 1:
		return false
	if not has_valid_target:
		return false
	if enemy_count > enemy_count_soft_limit and distance_to_target > max_target_distance:
		return false
	return true


static func estimate_candidate_path_length(
	navigation_map: RID,
	from_position: Vector3,
	candidate: Vector3,
	navigation_layers: int
) -> float:
	return measure_candidate_path_metrics(
		navigation_map,
		from_position,
		candidate,
		navigation_layers
	).length


static func estimate_candidate_path_end_error(
	navigation_map: RID,
	from_position: Vector3,
	candidate: Vector3,
	navigation_layers: int
) -> float:
	return measure_candidate_path_metrics(
		navigation_map,
		from_position,
		candidate,
		navigation_layers
	).end_error


static func measure_candidate_path_metrics(
	navigation_map: RID,
	from_position: Vector3,
	candidate: Vector3,
	navigation_layers: int
) -> CandidatePathMetrics:
	var result := CandidatePathMetrics.new()
	var path := _get_candidate_path(navigation_map, from_position, candidate, navigation_layers)
	if path.is_empty():
		return result

	var path_end: Vector3 = path[path.size() - 1]
	result.length = _measure_path_length(path)
	result.end_error = path_end.distance_to(candidate)
	return result


static func _project_candidate_to_nav(
	candidate: Vector3,
	navigation_map: RID,
	projection_tolerance: float,
	invalid_point: Vector3
) -> Vector3:
	var projected_candidate := NavigationServer3D.map_get_closest_point(navigation_map, candidate)
	if projected_candidate == Vector3.ZERO and NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
		return invalid_point

	if candidate.distance_to(projected_candidate) > projection_tolerance:
		return invalid_point

	return projected_candidate


static func _score_spread_penalty(
	candidate: Vector3,
	nearby_enemy_positions: Array[Vector3],
	spread_penalty_radius: float,
	spread_penalty_weight: float
) -> float:
	if spread_penalty_weight <= 0.0 or spread_penalty_radius <= 0.0:
		return 0.0

	var penalty := 0.0
	var spread_penalty_radius_sq := spread_penalty_radius * spread_penalty_radius
	for enemy_position in nearby_enemy_positions:
		var offset := enemy_position - candidate
		offset.y = 0.0
		var distance_sq := offset.length_squared()
		if distance_sq >= spread_penalty_radius_sq:
			continue

		var distance_to_enemy := sqrt(distance_sq)
		var normalized_overlap := 1.0 - (distance_to_enemy / spread_penalty_radius)
		penalty += normalized_overlap * spread_penalty_weight

	return penalty


static func _is_failed_goal_candidate(
	candidate: Vector3,
	recent_failed_goals: Array,
	failed_goal_exclusion_radius: float
) -> bool:
	for failed_goal in recent_failed_goals:
		if _horizontal_distance(candidate, failed_goal as Vector3) <= failed_goal_exclusion_radius:
			return true

	return false


static func _select_candidate_with_path_tiebreak(
	request: SelectGoalRequest,
	candidate_infos: Array[Dictionary],
	best_cheap_score: float
) -> Dictionary:
	if candidate_infos.is_empty():
		return {}

	var shortlist := _build_path_tiebreak_shortlist(
		candidate_infos,
		best_cheap_score,
		request.goal_path_tiebreak_candidate_count,
		request.goal_path_tiebreak_score_window
	)
	if shortlist.is_empty():
		return {}

	var valid_candidate_infos: Array[Dictionary] = []
	var unreachable_path_count := 0
	for candidate_info in shortlist:
		var projected_candidate := candidate_info["projected_candidate"] as Vector3
		var path_metrics := measure_candidate_path_metrics(
			request.navigation_map,
			request.global_position,
			projected_candidate,
			request.navigation_layers
		)
		var path_length := path_metrics.length
		var path_end_error := path_metrics.end_error
		candidate_info["path_length"] = path_length
		candidate_info["path_end_error"] = path_end_error
		if is_inf(path_length):
			unreachable_path_count += 1
			continue

		if path_end_error > request.goal_path_endpoint_tolerance:
			unreachable_path_count += 1
			continue

		valid_candidate_infos.append(candidate_info)

	if valid_candidate_infos.is_empty():
		return {
			"unreachable_path_count": unreachable_path_count,
		}

	if not should_use_path_tiebreak(
		request.goal_path_tiebreak_candidate_count,
		true,
		request.enemy_count,
		request.distance_to_target,
		request.goal_path_tiebreak_enemy_count_soft_limit,
		request.goal_path_tiebreak_max_target_distance
	):
		var best_without_tiebreak: Dictionary = valid_candidate_infos[0]
		best_without_tiebreak["unreachable_path_count"] = unreachable_path_count
		return best_without_tiebreak

	if valid_candidate_infos.size() == 1:
		var single_shortlist_info: Dictionary = valid_candidate_infos[0]
		single_shortlist_info["unreachable_path_count"] = unreachable_path_count
		return single_shortlist_info

	var best_info: Dictionary = valid_candidate_infos[0]
	var best_path_score := INF
	for candidate_info in valid_candidate_infos:
		var path_length := float(candidate_info["path_length"])
		var final_score := path_length + float(candidate_info["spread_score"])
		if final_score < best_path_score:
			best_path_score = final_score
			best_info = candidate_info

	best_info["unreachable_path_count"] = unreachable_path_count
	return best_info


static func _build_path_tiebreak_shortlist(
	candidate_infos: Array[Dictionary],
	best_cheap_score: float,
	shortlist_size: int,
	score_window: float
) -> Array[Dictionary]:
	if candidate_infos.is_empty():
		return []

	var shortlist: Array[Dictionary] = []
	var max_shortlist_size := maxi(shortlist_size, 1)
	var score_limit := best_cheap_score + maxf(score_window, 0.0)
	var ranked_indices: Array[int] = []

	for candidate_index in range(candidate_infos.size()):
		var cheap_score := float(candidate_infos[candidate_index]["cheap_score"])
		if cheap_score > score_limit:
			continue
		ranked_indices.append(candidate_index)

	ranked_indices.sort_custom(func(a: int, b: int) -> bool:
		return float(candidate_infos[a]["cheap_score"]) < float(candidate_infos[b]["cheap_score"])
	)

	for shortlist_index in range(mini(max_shortlist_size, ranked_indices.size())):
		shortlist.append(candidate_infos[ranked_indices[shortlist_index]])

	return shortlist



static func _select_direct_chase_goal(request: SelectGoalRequest) -> GoalSelectionResult:
	var result := GoalSelectionResult.new()
	var debug_info := GoalDebugInfo.new()
	debug_info.candidate_count = 1
	debug_info.used_fallback = true
	debug_info.raw_candidate = request.target_position
	var projected_candidate := _project_candidate_to_nav(
		request.target_position,
		request.navigation_map,
		request.candidate_projection_tolerance,
		request.invalid_point
	)
	if projected_candidate == request.invalid_point:
		result.debug = debug_info
		return result

	debug_info.projected_candidate = projected_candidate
	debug_info.projection_error = request.target_position.distance_to(projected_candidate)
	result.has_goal = true
	result.goal_position = projected_candidate
	result.goal_center = request.target_position
	result.debug = debug_info
	return result

static func _measure_path_length(path: PackedVector3Array) -> float:
	if path.size() < 2:
		return 0.0

	var total_length := 0.0
	for path_index in range(1, path.size()):
		total_length += path[path_index - 1].distance_to(path[path_index])

	return total_length


static func _get_candidate_path(
	navigation_map: RID,
	from_position: Vector3,
	candidate: Vector3,
	navigation_layers: int
) -> PackedVector3Array:
	return NavigationServer3D.map_get_path(
		navigation_map,
		from_position,
		candidate,
		true,
		navigation_layers
	)


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()

