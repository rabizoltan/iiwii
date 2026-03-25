extends RefCounted


static var _nav_cache_refresh_count: int = 0
static var _nav_cache_reuse_count: int = 0
static var _nav_resolve_count: int = 0
static var _nav_get_next_path_position_count: int = 0
static var _nav_path_scan_count: int = 0
static var _goal_select_count: int = 0
static var _goal_select_direct_count: int = 0
static var _goal_select_ring_count: int = 0
static var _goal_select_far_candidate_count: int = 0
static var _goal_select_missing_distance_count: int = 0
static var _path_metric_count: int = 0
static var _map_get_path_count: int = 0
static var _stuck_recovery_count: int = 0
static var _frontline_rejection_count: int = 0
static var _nearby_enemy_query_count: int = 0
static var _local_enemy_query_count: int = 0
static var _frontline_rank_query_count: int = 0


static func record_nav_cache_decision(refreshed: bool) -> void:
	if refreshed:
		_nav_cache_refresh_count += 1
	else:
		_nav_cache_reuse_count += 1


static func record_nav_resolve_call() -> void:
	_nav_resolve_count += 1


static func record_nav_step_query() -> void:
	_nav_get_next_path_position_count += 1


static func record_nav_path_scan() -> void:
	_nav_path_scan_count += 1


static func record_goal_selection(
	actual_distance_to_target: float,
	request_distance_to_target: float,
	direct_chase_distance: float,
	used_direct_chase: bool
) -> void:
	_goal_select_count += 1
	if used_direct_chase:
		_goal_select_direct_count += 1
	else:
		_goal_select_ring_count += 1

	if actual_distance_to_target > direct_chase_distance:
		_goal_select_far_candidate_count += 1

	if actual_distance_to_target > direct_chase_distance and request_distance_to_target <= direct_chase_distance:
		_goal_select_missing_distance_count += 1


static func record_path_metric_call() -> void:
	_path_metric_count += 1


static func record_map_get_path_call() -> void:
	_map_get_path_count += 1


static func record_stuck_recovery() -> void:
	_stuck_recovery_count += 1


static func record_frontline_rejection() -> void:
	_frontline_rejection_count += 1


static func record_nearby_enemy_query() -> void:
	_nearby_enemy_query_count += 1


static func record_local_enemy_query() -> void:
	_local_enemy_query_count += 1


static func record_frontline_rank_query() -> void:
	_frontline_rank_query_count += 1


static func get_snapshot() -> Dictionary:
	return {
		"nav_cache_refresh_count": _nav_cache_refresh_count,
		"nav_cache_reuse_count": _nav_cache_reuse_count,
		"nav_resolve_count": _nav_resolve_count,
		"nav_get_next_path_position_count": _nav_get_next_path_position_count,
		"nav_path_scan_count": _nav_path_scan_count,
		"goal_select_count": _goal_select_count,
		"goal_select_direct_count": _goal_select_direct_count,
		"goal_select_ring_count": _goal_select_ring_count,
		"goal_select_far_candidate_count": _goal_select_far_candidate_count,
		"goal_select_missing_distance_count": _goal_select_missing_distance_count,
		"path_metric_count": _path_metric_count,
		"map_get_path_count": _map_get_path_count,
		"stuck_recovery_count": _stuck_recovery_count,
		"frontline_rejection_count": _frontline_rejection_count,
		"nearby_enemy_query_count": _nearby_enemy_query_count,
		"local_enemy_query_count": _local_enemy_query_count,
		"frontline_rank_query_count": _frontline_rank_query_count,
	}
