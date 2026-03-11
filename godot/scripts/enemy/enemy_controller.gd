extends CharacterBody3D

static var _enemy_registry: Array[Node3D] = []
static var _profiling_enabled: bool = false
static var _profile_window_start_usec: int = 0
static var _profile_physics_total_usec: int = 0
static var _profile_goal_total_usec: int = 0
static var _profile_yield_total_usec: int = 0
static var _profile_label_total_usec: int = 0
static var _profile_nav_debug_total_usec: int = 0
static var _profile_nav_query_total_usec: int = 0
static var _profile_move_slide_total_usec: int = 0
static var _profile_physics_calls: int = 0
static var _profile_goal_calls: int = 0
static var _profile_yield_calls: int = 0

enum MeleeCloseState {
	APPROACH,
	CLOSE_ADJUST,
	MELEE_HOLD,
}

# Movement and targeting
@export var move_speed: float = 4.5
@export var turn_speed: float = 8.0
@export var target_path: NodePath

# Debug and health
@export var debug_enabled: bool = true
@export var debug_log_enabled: bool = false
@export var melee_hold_debug_enabled: bool = true
@export var show_hp_label: bool = true
@export var max_hp: float = 3.0

# Melee engage behavior
@export var melee_engage_distance: float = 1.8
@export var engage_hold_tolerance: float = 0.35
@export var engage_vertical_tolerance: float = 1.0
@export var close_adjust_enter_distance: float = 2.6
@export var close_adjust_move_speed: float = 2.8
@export var close_adjust_neighbor_radius: float = 1.5
@export var close_adjust_probe_distance: float = 0.9
@export var close_adjust_min_lateral_weight: float = 0.2
@export var close_adjust_max_lateral_weight: float = 1.15
@export var close_adjust_stop_distance: float = 0.18
@export var close_adjust_gap_stop_distance: float = 0.12
@export var close_adjust_side_commit_duration: float = 0.3
@export var close_adjust_side_switch_penalty_margin: float = 0.12
@export var close_adjust_nav_refresh_interval: float = 0.12

# Player-vs-crowd pressure response
@export var player_push_yield_distance: float = 1.2
@export var player_push_yield_speed: float = 4.2
@export var player_push_side_yield_weight: float = 1.0
@export var player_push_block_check_distance: float = 0.8
@export var player_push_block_neighbor_radius: float = 1.8
@export var player_push_min_yield_factor: float = 0.6
@export var player_collision_push_decay: float = 10.0
@export var player_collision_push_max_speed: float = 4.8
@export var player_collision_push_lateral_weight: float = 1.2
@export var player_collision_push_outward_weight: float = 0.35
@export var crowd_chain_yield_distance: float = 2.2
@export var crowd_chain_neighbor_radius: float = 1.1
@export var crowd_chain_yield_bonus: float = 1.1
@export var local_enemy_cache_interval: float = 0.12

# Goal selection
@export var goal_commit_duration: float = 0.6
@export var goal_select_min_interval: float = 0.2
@export var goal_select_start_jitter: float = 0.2
@export var goal_reacquire_distance: float = 0.9
@export var engage_candidate_count: int = 10
@export var goal_path_tiebreak_candidate_count: int = 3
@export var goal_path_tiebreak_score_window: float = 0.75
@export var goal_path_tiebreak_max_target_distance: float = 8.0
@export var goal_path_tiebreak_enemy_count_soft_limit: int = 24
@export var spread_penalty_radius: float = 1.2
@export var spread_penalty_weight: float = 0.35
@export var candidate_projection_tolerance: float = 1.0
@export var failed_goal_exclusion_radius: float = 0.75
@export var failed_goal_memory_count: int = 2
@export var nav_refresh_interval_near: float = 0.0
@export var nav_refresh_interval_far: float = 0.02
@export var nav_refresh_far_distance: float = 10.0

# Minimal stuck fallback
@export var stuck_timeout: float = 0.35
@export var stuck_recovery_duration: float = 0.3
@export var stuck_min_progress_distance: float = 0.02

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _debug_label: Label3D = $DebugLabel3D
@onready var _nav_path_debug: MeshInstance3D = $NavPathDebug

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_node: Node3D
var _debug_overlay_cache: Node
var _last_debug_write_msec: int = 0
var _last_melee_hold_log_msec: int = 0
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0
var _nav_path_mesh: ImmediateMesh
var _melee_state: MeleeCloseState = MeleeCloseState.APPROACH
var _melee_state_age: float = 0.0
var _melee_state_transition_count: int = 0
var _has_goal: bool = false
var _current_goal_position: Vector3 = Vector3.ZERO
var _goal_center_at_selection: Vector3 = Vector3.ZERO
var _goal_commit_remaining: float = 0.0
var _goal_select_cooldown_remaining: float = 0.0
var _goal_age: float = 0.0
var _recent_failed_goals: Array[Vector3] = []
var _debug_candidate_positions: PackedVector3Array = PackedVector3Array()
var _local_enemy_cache_positions: Array[Vector3] = []
var _local_enemy_cache_radius: float = 0.0
var _local_enemy_cache_remaining: float = 0.0
var _nav_refresh_remaining: float = 0.0
var _cached_nav_next_position: Vector3 = Vector3.ZERO
var _cached_nav_move_target: Vector3 = Vector3(INF, INF, INF)
var _player_collision_push_velocity: Vector3 = Vector3.ZERO
var _close_adjust_side_sign: float = 0.0
var _close_adjust_side_commit_remaining: float = 0.0
var _debug_nav_cache_refreshed: bool = false
var _debug_close_adjust_path_distance: float = 0.0
var _debug_close_adjust_target_gap: float = 0.0
var _debug_close_adjust_crowd_pressure: float = 0.0
var _debug_close_adjust_left_penalty: float = 0.0
var _debug_close_adjust_right_penalty: float = 0.0
var _debug_close_adjust_side_sign: float = 0.0
var _debug_close_adjust_lateral_weight: float = 0.0
var _debug_close_adjust_move_speed: float = 0.0
var _debug_hold_displacement: float = 0.0
var _debug_hold_velocity: float = 0.0
var _debug_hold_collision_count: int = 0
var _debug_hold_collision_names: Array[String] = []
var _debug_hold_has_yield: bool = false
var _debug_yield_speed: float = 0.0
var _debug_yield_strength: float = 0.0
var _debug_yield_neighbor_count: int = 0
var _debug_yield_penalty: float = 0.0
var _debug_yield_direction: Vector3 = Vector3.ZERO
var _debug_crowd_pressure: float = 0.0
var _debug_yield_direct_pressure: float = 0.0
var _debug_yield_chain_pressure: float = 0.0
var _debug_goal_candidate_count: int = 0
var _debug_goal_rejected_projection_count: int = 0
var _debug_goal_rejected_failed_count: int = 0
var _debug_goal_used_fallback: bool = false
var _debug_goal_raw_candidate: Vector3 = Vector3.ZERO
var _debug_goal_projected_candidate: Vector3 = Vector3.ZERO
var _debug_goal_projection_error: float = 0.0
var _debug_goal_path_end: Vector3 = Vector3.ZERO
var _debug_goal_path_end_error: float = 0.0
var _path_debug_material: StandardMaterial3D
var _goal_debug_material: StandardMaterial3D
var _candidate_debug_material: StandardMaterial3D
var _debug_label_refresh_remaining: float = 0.0
var _nav_debug_refresh_remaining: float = 0.0

const DEBUG_LOG_PATH := "user://debug/enemy_debug.log"
const MELEE_HOLD_DEBUG_PATH := "user://debug/enemy_melee_hold_debug.txt"
const DEBUG_WRITE_INTERVAL_MSEC := 500
const MELEE_HOLD_DEBUG_INTERVAL_MSEC := 100
const MELEE_HOLD_DISPLACEMENT_LOG_THRESHOLD := 0.01
const INVALID_POINT := Vector3(INF, INF, INF)
const DEBUG_LABEL_REFRESH_INTERVAL_SEC := 0.12
const NAV_DEBUG_REFRESH_INTERVAL_SEC := 0.12


# Lifecycle
func _enter_tree() -> void:
	if not _enemy_registry.has(self):
		_enemy_registry.append(self)


func _exit_tree() -> void:
	_enemy_registry.erase(self)


func _ready() -> void:
	_current_hp = max_hp
	_goal_select_cooldown_remaining = randf() * maxf(goal_select_start_jitter, 0.0)
	_nav_path_mesh = ImmediateMesh.new()
	_nav_path_debug.mesh = _nav_path_mesh
	_path_debug_material = _build_debug_material(Color(0.95, 0.85, 0.2, 1.0))
	_goal_debug_material = _build_debug_material(Color(0.2, 0.9, 0.45, 1.0))
	_candidate_debug_material = _build_debug_material(Color(0.35, 0.7, 1.0, 0.8))
	_nav_agent.set_navigation_map(get_world_3d().navigation_map)
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = engage_hold_tolerance
	call_deferred("_resolve_target")
	_prepare_debug_log()
	_prepare_melee_hold_debug_log()
	_refresh_label("idle", Vector3.ZERO, 0)


func _resolve_target() -> void:
	_target_node = null
	if not target_path.is_empty():
		_target_node = get_node_or_null(target_path) as Node3D

	if _target_node == null:
		_target_node = get_tree().get_first_node_in_group("player") as Node3D


# Main update loop
func _physics_process(delta: float) -> void:
	var physics_start_usec := Time.get_ticks_usec()
	var pre_move_position := global_position
	var debug_state := "idle"
	var debug_next_position := Vector3.ZERO
	var debug_iteration_id := 0
	var attempted_horizontal_move := false
	_reset_yield_debug_state()
	_reset_close_adjust_debug_state()

	if _goal_commit_remaining > 0.0:
		_goal_commit_remaining = maxf(_goal_commit_remaining - delta, 0.0)

	if _goal_select_cooldown_remaining > 0.0:
		_goal_select_cooldown_remaining = maxf(_goal_select_cooldown_remaining - delta, 0.0)

	if _local_enemy_cache_remaining > 0.0:
		_local_enemy_cache_remaining = maxf(_local_enemy_cache_remaining - delta, 0.0)

	if _nav_refresh_remaining > 0.0:
		_nav_refresh_remaining = maxf(_nav_refresh_remaining - delta, 0.0)

	if _debug_label_refresh_remaining > 0.0:
		_debug_label_refresh_remaining = maxf(_debug_label_refresh_remaining - delta, 0.0)

	if _nav_debug_refresh_remaining > 0.0:
		_nav_debug_refresh_remaining = maxf(_nav_debug_refresh_remaining - delta, 0.0)

	if _close_adjust_side_commit_remaining > 0.0:
		_close_adjust_side_commit_remaining = maxf(_close_adjust_side_commit_remaining - delta, 0.0)

	if _has_goal:
		_goal_age += delta
	else:
		_goal_age = 0.0

	_melee_state_age += delta

	if not _has_valid_target():
		_target_node = null
		_resolve_target()

	if not _has_valid_target():
		_has_goal = false
		_invalidate_navigation_cache()
		velocity.x = 0.0
		velocity.z = 0.0
		debug_state = "no target"
	else:
		var distance_to_target: float = _horizontal_distance_to(_target_node.global_position)
		_update_melee_state(_target_node.global_position)
		var iteration_id := NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map())
		debug_iteration_id = iteration_id
		if iteration_id == 0:
			velocity.x = 0.0
			velocity.z = 0.0
			debug_state = "nav not ready"
			_update_debug(debug_state, debug_next_position, debug_iteration_id)
			var move_slide_start_usec := _profile_start_usec()
			move_and_slide()
			_record_profile_duration("move_slide", Time.get_ticks_usec() - move_slide_start_usec)
			_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)
			return

		match _melee_state:
			MeleeCloseState.APPROACH:
				if _should_refresh_goal():
					_select_engage_goal()
					_reset_goal_select_cooldown()

				var approach_result := _run_approach_state(delta, distance_to_target)
				debug_state = str(approach_result.get("state", "approach"))
				debug_next_position = approach_result.get("next_position", Vector3.ZERO)
				attempted_horizontal_move = approach_result.get("attempted_move", false)
			MeleeCloseState.CLOSE_ADJUST:
				var close_adjust_result := _run_close_adjust_state(delta, distance_to_target)
				debug_state = str(close_adjust_result.get("state", "close_adjust"))
				debug_next_position = close_adjust_result.get("next_position", global_position)
				attempted_horizontal_move = close_adjust_result.get("attempted_move", false)
			MeleeCloseState.MELEE_HOLD:
				var hold_result := _run_melee_hold_state(delta)
				debug_state = str(hold_result.get("state", "melee_hold"))
				debug_next_position = hold_result.get("next_position", global_position)
				attempted_horizontal_move = hold_result.get("attempted_move", false)

		if _apply_player_collision_push(delta):
			attempted_horizontal_move = true

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var move_slide_start_usec := _profile_start_usec()
	move_and_slide()
	_record_profile_duration("move_slide", Time.get_ticks_usec() - move_slide_start_usec)
	_capture_melee_hold_runtime_debug(pre_move_position, debug_state, debug_next_position)
	_update_stuck_state(delta, pre_move_position, attempted_horizontal_move)
	_update_debug(debug_state, debug_next_position, debug_iteration_id)
	_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)


# Goal selection and candidate scoring
func _should_refresh_goal() -> bool:
	if not _has_valid_target():
		return false

	if _goal_select_cooldown_remaining > 0.0:
		return false

	if not _has_goal:
		return true

	if _goal_commit_remaining > 0.0:
		return false

	var target_shift := _horizontal_distance(_goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return true

	var goal_distance := _horizontal_distance(global_position, _current_goal_position)
	return goal_distance <= maxf(engage_hold_tolerance, 0.25)


func _select_engage_goal() -> void:
	var profile_start_usec := _profile_start_usec()
	_reset_goal_debug_state()
	if _target_node == null:
		_has_goal = false
		_invalidate_navigation_cache()
		_debug_candidate_positions = PackedVector3Array()
		_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
		return

	var target_position := _target_node.global_position
	var center := target_position
	var candidate_positions := PackedVector3Array()
	var capture_candidate_debug := _should_capture_candidate_debug()
	var nearby_enemy_positions := _collect_nearby_enemy_positions(center)
	var candidate_infos: Array[Dictionary] = []
	var best_score := INF
	var best_candidate := Vector3.ZERO
	var base_direction := global_position - center
	base_direction.y = 0.0
	if base_direction.length_squared() == 0.0:
		base_direction = Vector3.FORWARD

	var base_angle := atan2(base_direction.z, base_direction.x)
	var candidate_count := maxi(engage_candidate_count, 4)
	_debug_goal_candidate_count = candidate_count

	for candidate_index in range(candidate_count):
		var angle := base_angle + (TAU * float(candidate_index) / float(candidate_count))
		var raw_candidate := center + Vector3(cos(angle), 0.0, sin(angle)) * melee_engage_distance
		var projected_candidate := _project_candidate_to_nav(raw_candidate)
		if projected_candidate == INVALID_POINT:
			_debug_goal_rejected_projection_count += 1
			continue

		if capture_candidate_debug:
			candidate_positions.append(projected_candidate)

		if _is_failed_goal_candidate(projected_candidate):
			_debug_goal_rejected_failed_count += 1
			continue

		var spread_score := _score_spread_penalty(projected_candidate, nearby_enemy_positions)
		var score := _score_candidate(projected_candidate, spread_score)
		candidate_infos.append({
			"raw_candidate": raw_candidate,
			"projected_candidate": projected_candidate,
			"spread_score": spread_score,
			"cheap_score": score,
		})
		if score < best_score:
			best_score = score

	if best_score == INF:
		var fallback_candidate := _project_candidate_to_nav(center)
		if fallback_candidate == INVALID_POINT:
			_has_goal = false
			_invalidate_navigation_cache()
			_debug_candidate_positions = candidate_positions if capture_candidate_debug else PackedVector3Array()
			_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
			return

		_debug_goal_used_fallback = true
		_debug_goal_raw_candidate = center
		_debug_goal_projected_candidate = fallback_candidate
		_debug_goal_projection_error = _horizontal_distance(center, fallback_candidate)
		best_candidate = fallback_candidate
	else:
		var selected_candidate_info := _select_candidate_with_path_tiebreak(candidate_infos, best_score)
		_debug_goal_raw_candidate = selected_candidate_info["raw_candidate"] as Vector3
		_debug_goal_projected_candidate = selected_candidate_info["projected_candidate"] as Vector3
		_debug_goal_projection_error = _horizontal_distance(_debug_goal_raw_candidate, _debug_goal_projected_candidate)
		best_candidate = _debug_goal_projected_candidate

	_current_goal_position = best_candidate
	_goal_center_at_selection = center
	_goal_commit_remaining = goal_commit_duration
	_goal_age = 0.0
	_has_goal = true
	_invalidate_navigation_cache()
	_capture_goal_path_debug()
	_debug_candidate_positions = candidate_positions if capture_candidate_debug else PackedVector3Array()
	_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)


func _project_candidate_to_nav(candidate: Vector3) -> Vector3:
	var profile_start_usec := _profile_start_usec()
	var navigation_map := _nav_agent.get_navigation_map()
	var projected_candidate := NavigationServer3D.map_get_closest_point(navigation_map, candidate)
	if projected_candidate == Vector3.ZERO and NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
		_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
		return INVALID_POINT

	if _horizontal_distance(candidate, projected_candidate) > candidate_projection_tolerance:
		_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
		return INVALID_POINT

	_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
	return projected_candidate

func _score_candidate(candidate: Vector3, spread_score: float) -> float:
	var movement_score := _horizontal_distance(global_position, candidate)
	return movement_score + spread_score


func _select_candidate_with_path_tiebreak(candidate_infos: Array[Dictionary], best_cheap_score: float) -> Dictionary:
	if candidate_infos.is_empty():
		return {}

	if not _should_use_path_tiebreak():
		return _build_path_tiebreak_shortlist(candidate_infos, best_cheap_score)[0]

	var shortlist := _build_path_tiebreak_shortlist(candidate_infos, best_cheap_score)
	if shortlist.size() <= 1:
		return shortlist[0] if not shortlist.is_empty() else candidate_infos[0]

	var best_info: Dictionary = shortlist[0]
	var best_path_score := INF
	for candidate_info in shortlist:
		var projected_candidate := candidate_info["projected_candidate"] as Vector3
		var path_length := _estimate_candidate_path_length(projected_candidate)
		if is_inf(path_length):
			continue

		var final_score := path_length + float(candidate_info["spread_score"])
		if final_score < best_path_score:
			best_path_score = final_score
			best_info = candidate_info

	return best_info


func _build_path_tiebreak_shortlist(candidate_infos: Array[Dictionary], best_cheap_score: float) -> Array[Dictionary]:
	if candidate_infos.is_empty():
		return []

	var shortlist: Array[Dictionary] = []
	var max_shortlist_size := maxi(goal_path_tiebreak_candidate_count, 1)
	var score_limit := best_cheap_score + maxf(goal_path_tiebreak_score_window, 0.0)
	var used_indices: Array[int] = []

	while shortlist.size() < max_shortlist_size:
		var best_index := -1
		var next_score := INF
		for candidate_index in range(candidate_infos.size()):
			if used_indices.has(candidate_index):
				continue

			var cheap_score := float(candidate_infos[candidate_index]["cheap_score"])
			if cheap_score > score_limit and not shortlist.is_empty():
				continue

			if cheap_score < next_score:
				next_score = cheap_score
				best_index = candidate_index

		if best_index == -1:
			break

		used_indices.append(best_index)
		shortlist.append(candidate_infos[best_index])

	return shortlist


func _estimate_candidate_path_length(candidate: Vector3) -> float:
	var profile_start_usec := _profile_start_usec()
	var navigation_map := _nav_agent.get_navigation_map()
	var path := NavigationServer3D.map_get_path(
		navigation_map,
		global_position,
		candidate,
		true,
		_nav_agent.navigation_layers
	)
	_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
	if path.is_empty():
		return INF

	return _measure_path_length(path)


func _measure_path_length(path: PackedVector3Array) -> float:
	if path.size() < 2:
		return 0.0

	var total_length := 0.0
	for path_index in range(1, path.size()):
		total_length += path[path_index - 1].distance_to(path[path_index])

	return total_length


func _should_use_path_tiebreak() -> bool:
	if goal_path_tiebreak_candidate_count <= 1:
		return false

	if not _has_valid_target():
		return false

	var enemy_count := _enemy_registry.size()
	var distance_to_target := _horizontal_distance_to(_target_node.global_position)
	if enemy_count > goal_path_tiebreak_enemy_count_soft_limit and distance_to_target > goal_path_tiebreak_max_target_distance:
		return false

	return true


func _reset_goal_select_cooldown() -> void:
	_goal_select_cooldown_remaining = maxf(goal_select_min_interval, 0.0)


func _score_spread_penalty(candidate: Vector3, nearby_enemy_positions: Array[Vector3]) -> float:
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


func _collect_nearby_enemy_positions(center: Vector3) -> Array[Vector3]:
	var nearby_positions: Array[Vector3] = []
	if spread_penalty_weight <= 0.0 or spread_penalty_radius <= 0.0:
		return nearby_positions

	var relevant_radius := melee_engage_distance + spread_penalty_radius
	var relevant_radius_sq := relevant_radius * relevant_radius
	for enemy in _enemy_registry:
		if enemy == null or enemy == self or not is_instance_valid(enemy):
			continue

		var offset := enemy.global_position - center
		offset.y = 0.0
		if offset.length_squared() > relevant_radius_sq:
			continue

		nearby_positions.append(enemy.global_position)

	return nearby_positions


func _is_failed_goal_candidate(candidate: Vector3) -> bool:
	for failed_goal in _recent_failed_goals:
		if _horizontal_distance(candidate, failed_goal) <= failed_goal_exclusion_radius:
			return true

	return false


func _remember_failed_goal(goal_position: Vector3) -> void:
	if failed_goal_memory_count <= 0:
		_recent_failed_goals.clear()
		return

	_recent_failed_goals.append(goal_position)
	while _recent_failed_goals.size() > failed_goal_memory_count:
		_recent_failed_goals.remove_at(0)


func _is_in_melee_hold(target_position: Vector3) -> bool:
	var vertical_offset := absf(target_position.y - global_position.y)
	if vertical_offset > engage_vertical_tolerance:
		return false

	return _horizontal_distance(global_position, target_position) <= melee_engage_distance + engage_hold_tolerance


func _is_in_close_adjust_band(target_position: Vector3) -> bool:
	var vertical_offset := absf(target_position.y - global_position.y)
	if vertical_offset > engage_vertical_tolerance:
		return false

	return _horizontal_distance(global_position, target_position) <= maxf(close_adjust_enter_distance, melee_engage_distance + engage_hold_tolerance)


func _update_melee_state(target_position: Vector3) -> void:
	var next_state := MeleeCloseState.APPROACH
	if _is_in_melee_hold(target_position):
		next_state = MeleeCloseState.MELEE_HOLD
	elif _is_in_close_adjust_band(target_position):
		next_state = MeleeCloseState.CLOSE_ADJUST

	if next_state == _melee_state:
		return

	_melee_state = next_state
	_melee_state_age = 0.0
	_melee_state_transition_count += 1
	if _melee_state != MeleeCloseState.APPROACH:
		_stuck_elapsed = 0.0
		_recovery_elapsed = 0.0
	if _melee_state != MeleeCloseState.CLOSE_ADJUST:
		_close_adjust_side_sign = 0.0
		_close_adjust_side_commit_remaining = 0.0


func _run_approach_state(delta: float, distance_to_target: float) -> Dictionary:
	var move_target: Vector3 = _current_goal_position if _has_goal else _target_node.global_position
	var next_position := _get_navigation_next_position(move_target, distance_to_target)
	var horizontal_offset: Vector3 = next_position - global_position
	horizontal_offset.y = 0.0

	if _nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		_face_position(_target_node.global_position, delta)
		return {
			"state": "%s:arrived" % _get_melee_state_name(),
			"next_position": next_position,
			"attempted_move": false,
		}

	if horizontal_offset.length_squared() <= 0.04:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_position(_target_node.global_position, delta)
		return {
			"state": "%s:at_next" % _get_melee_state_name(),
			"next_position": next_position,
			"attempted_move": false,
		}

	var move_direction: Vector3 = horizontal_offset.normalized()
	var state_label := "%s:moving" % _get_melee_state_name()
	if _recovery_elapsed > 0.0:
		var recovery_tangent := Vector3(-move_direction.z, 0.0, move_direction.x) * _recovery_sign
		move_direction = (move_direction * 0.25 + recovery_tangent).normalized()
		_recovery_elapsed = maxf(_recovery_elapsed - delta, 0.0)
		state_label = "%s:recovering" % _get_melee_state_name()

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	_face_position(global_position + move_direction, delta)
	return {
		"state": state_label,
		"next_position": next_position,
		"attempted_move": true,
	}


func _run_close_adjust_state(delta: float, distance_to_target: float) -> Dictionary:
	var move_target := _get_close_adjust_move_target()
	var next_position := _get_navigation_next_position(move_target, distance_to_target)
	var move_velocity := _compute_close_adjust_velocity(next_position)
	if move_velocity == Vector3.ZERO:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_position(_target_node.global_position, delta)
		return {
			"state": "%s:settling" % _get_melee_state_name(),
			"next_position": next_position,
			"attempted_move": false,
		}

	velocity.x = move_velocity.x
	velocity.z = move_velocity.z
	_face_position(_target_node.global_position, delta)
	return {
		"state": "%s:moving" % _get_melee_state_name(),
		"next_position": next_position,
		"attempted_move": true,
	}


func _compute_close_adjust_velocity(next_position: Vector3) -> Vector3:
	if _target_node == null:
		return Vector3.ZERO

	var distance_to_target := _horizontal_distance_to(_target_node.global_position)
	var path_direction := next_position - global_position
	path_direction.y = 0.0
	var path_distance := path_direction.length()
	_debug_close_adjust_path_distance = path_distance
	if path_direction.length_squared() <= 0.0001:
		path_direction = _target_node.global_position - global_position
		path_direction.y = 0.0

	if path_direction.length_squared() <= 0.0001:
		return Vector3.ZERO

	var move_direction := path_direction.normalized()
	var away_direction := global_position - _target_node.global_position
	away_direction.y = 0.0
	if away_direction.length_squared() <= 0.0001:
		away_direction = -move_direction
	else:
		away_direction = away_direction.normalized()

	var local_enemy_positions := _get_cached_local_enemy_positions(close_adjust_neighbor_radius)
	var crowd_pressure := _compute_crowd_pressure(local_enemy_positions)
	_debug_close_adjust_crowd_pressure = crowd_pressure
	var target_gap := maxf(distance_to_target - (melee_engage_distance + engage_hold_tolerance), 0.0)
	_debug_close_adjust_target_gap = target_gap
	if path_distance <= close_adjust_stop_distance and target_gap <= close_adjust_gap_stop_distance:
		return Vector3.ZERO

	var lateral_direction := _choose_close_adjust_lateral_direction(away_direction, local_enemy_positions)
	var lateral_weight := lerpf(
		close_adjust_min_lateral_weight,
		close_adjust_max_lateral_weight,
		clampf(crowd_pressure, 0.0, 1.0)
	)
	_debug_close_adjust_lateral_weight = lateral_weight
	var desired_direction := move_direction
	if lateral_direction != Vector3.ZERO:
		desired_direction = (move_direction + lateral_direction * lateral_weight).normalized()

	if desired_direction.length_squared() <= 0.0001:
		return Vector3.ZERO

	_debug_close_adjust_move_speed = close_adjust_move_speed
	return desired_direction * close_adjust_move_speed


func _get_close_adjust_move_target() -> Vector3:
	if _target_node == null:
		return global_position

	if not _has_goal:
		return _target_node.global_position

	var target_shift := _horizontal_distance(_goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return _target_node.global_position

	return _current_goal_position


func _choose_close_adjust_lateral_direction(
	away_direction: Vector3,
	local_enemy_positions: Array[Vector3]
) -> Vector3:
	var left_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var right_direction := -left_direction
	var left_penalty := _score_close_adjust_lateral_penalty(left_direction, local_enemy_positions)
	var right_penalty := _score_close_adjust_lateral_penalty(right_direction, local_enemy_positions)
	_debug_close_adjust_left_penalty = left_penalty
	_debug_close_adjust_right_penalty = right_penalty

	var preferred_sign := -1.0 if left_penalty <= right_penalty else 1.0
	var preferred_penalty := left_penalty if preferred_sign < 0.0 else right_penalty
	var current_penalty := preferred_penalty
	if _close_adjust_side_sign < 0.0:
		current_penalty = left_penalty
	elif _close_adjust_side_sign > 0.0:
		current_penalty = right_penalty

	if _close_adjust_side_sign == 0.0:
		_close_adjust_side_sign = preferred_sign
		_close_adjust_side_commit_remaining = close_adjust_side_commit_duration
	elif preferred_sign != _close_adjust_side_sign:
		var penalty_delta := current_penalty - preferred_penalty
		if _close_adjust_side_commit_remaining <= 0.0 and penalty_delta >= close_adjust_side_switch_penalty_margin:
			_close_adjust_side_sign = preferred_sign
			_close_adjust_side_commit_remaining = close_adjust_side_commit_duration

	_debug_close_adjust_side_sign = _close_adjust_side_sign
	return left_direction if _close_adjust_side_sign < 0.0 else right_direction


func _score_close_adjust_lateral_penalty(direction: Vector3, local_enemy_positions: Array[Vector3]) -> float:
	if close_adjust_probe_distance <= 0.0 or direction.length_squared() <= 0.0001:
		return 0.0

	var probe_position := global_position + direction * close_adjust_probe_distance
	var probe_distance_sq := close_adjust_probe_distance * close_adjust_probe_distance
	var penalty := 0.0
	for enemy_position in local_enemy_positions:
		var offset := enemy_position - probe_position
		offset.y = 0.0
		var distance_sq := offset.length_squared()
		if distance_sq >= probe_distance_sq:
			continue

		var distance_to_enemy := sqrt(distance_sq)
		penalty += 1.0 - (distance_to_enemy / close_adjust_probe_distance)

	return penalty


func _run_melee_hold_state(delta: float) -> Dictionary:
	var hold_velocity := _compute_player_yield_velocity(false)
	if hold_velocity != Vector3.ZERO:
		velocity.x = hold_velocity.x
		velocity.z = hold_velocity.z
		_face_position(_target_node.global_position, delta)
		return {
			"state": "%s:yielding" % _get_melee_state_name(),
			"next_position": global_position,
			"attempted_move": true,
		}

	velocity.x = 0.0
	velocity.z = 0.0
	_face_position(_target_node.global_position, delta)
	_close_adjust_side_sign = 0.0
	_close_adjust_side_commit_remaining = 0.0
	return {
		"state": "%s:holding" % _get_melee_state_name(),
		"next_position": global_position,
		"attempted_move": false,
	}


func _get_melee_state_name() -> String:
	match _melee_state:
		MeleeCloseState.APPROACH:
			return "approach"
		MeleeCloseState.CLOSE_ADJUST:
			return "close_adjust"
		MeleeCloseState.MELEE_HOLD:
			return "melee_hold"

	return "unknown"


# Crowd-pressure response
func _compute_player_yield_velocity(allow_chain_pressure: bool = true) -> Vector3:
	var profile_start_usec := _profile_start_usec()
	if _target_node == null or player_push_yield_distance <= 0.0:
		_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
		return Vector3.ZERO

	var offset := global_position - _target_node.global_position
	offset.y = 0.0
	var distance_to_target: float = offset.length()
	var away_direction: Vector3 = Vector3.FORWARD if distance_to_target <= 0.0001 else offset / distance_to_target
	var local_enemy_positions: Array[Vector3] = _get_cached_local_enemy_positions(player_push_block_neighbor_radius)
	_debug_yield_neighbor_count = local_enemy_positions.size()
	var crowd_pressure: float = _compute_crowd_pressure(local_enemy_positions)
	_debug_crowd_pressure = crowd_pressure
	var direct_pressure: float = 0.0
	if distance_to_target < player_push_yield_distance:
		direct_pressure = 1.0 - clampf(distance_to_target / player_push_yield_distance, 0.0, 1.0)
	_debug_yield_direct_pressure = direct_pressure

	var chain_pressure: float = 0.0
	if allow_chain_pressure and crowd_chain_yield_distance > player_push_yield_distance and distance_to_target < crowd_chain_yield_distance:
		var chain_ratio := 1.0 - clampf(
			(distance_to_target - player_push_yield_distance) / (crowd_chain_yield_distance - player_push_yield_distance),
			0.0,
			1.0
		)
		chain_pressure = crowd_pressure * chain_ratio
	_debug_yield_chain_pressure = chain_pressure

	var yield_activation: float = maxf(direct_pressure, chain_pressure)
	if yield_activation <= 0.0:
		_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
		return Vector3.ZERO

	var best_response: Dictionary = _choose_best_yield_response(away_direction, local_enemy_positions)
	var best_direction: Vector3 = best_response["direction"] as Vector3
	_debug_yield_direction = best_direction
	_debug_yield_penalty = float(best_response["penalty"])
	if best_direction == Vector3.ZERO:
		_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
		return Vector3.ZERO

	var yield_strength: float = float(best_response["strength"])
	var boosted_strength: float = clampf(yield_strength + crowd_pressure * crowd_chain_yield_bonus, player_push_min_yield_factor, 1.6)
	_debug_yield_strength = boosted_strength
	var yield_speed: float = player_push_yield_speed * yield_activation * boosted_strength
	_debug_yield_speed = yield_speed
	if yield_speed <= 0.01:
		_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
		return Vector3.ZERO

	var result := best_direction * yield_speed
	_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
	return result


func _choose_best_yield_response(
	away_direction: Vector3,
	local_enemy_positions: Array[Vector3]
) -> Dictionary:
	var side_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var candidate_directions: Array[Dictionary] = [
		{"direction": away_direction, "bias": 1.0},
		{"direction": (away_direction + side_direction * player_push_side_yield_weight).normalized(), "bias": 1.08},
		{"direction": (away_direction - side_direction * player_push_side_yield_weight).normalized(), "bias": 1.08},
	]

	var best_direction := Vector3.ZERO
	var best_penalty := INF
	for candidate in candidate_directions:
		var direction: Vector3 = candidate["direction"]
		if direction.length_squared() <= 0.0001:
			continue

		var penalty := _score_yield_direction_penalty(direction, local_enemy_positions) * float(candidate["bias"])
		if penalty < best_penalty:
			best_penalty = penalty
			best_direction = direction

	if best_direction == Vector3.ZERO:
		return {"direction": Vector3.ZERO, "strength": 0.0, "penalty": INF}

	var strength := clampf(1.0 - best_penalty, player_push_min_yield_factor, 1.0)
	return {
		"direction": best_direction,
		"strength": strength,
		"penalty": best_penalty,
	}


func _score_yield_direction_penalty(direction: Vector3, local_enemy_positions: Array[Vector3]) -> float:
	if player_push_block_check_distance <= 0.0:
		return 0.0

	var probe_position := global_position + direction * player_push_block_check_distance
	var block_radius_sq := player_push_block_check_distance * player_push_block_check_distance
	var penalty := 0.0
	for enemy_position in local_enemy_positions:
		var offset := enemy_position - probe_position
		offset.y = 0.0
		var distance_sq := offset.length_squared()
		if distance_sq >= block_radius_sq:
			continue

		var distance_to_enemy := sqrt(distance_sq)
		penalty += 1.0 - (distance_to_enemy / player_push_block_check_distance)

	return penalty


func _get_cached_local_enemy_positions(radius: float) -> Array[Vector3]:
	if radius <= 0.0:
		return []

	if _local_enemy_cache_remaining > 0.0 and _local_enemy_cache_radius >= radius:
		return _local_enemy_cache_positions

	_local_enemy_cache_positions = _collect_local_enemy_positions(radius)
	_local_enemy_cache_radius = radius
	_local_enemy_cache_remaining = local_enemy_cache_interval
	return _local_enemy_cache_positions


func _collect_local_enemy_positions(radius: float) -> Array[Vector3]:
	var local_positions: Array[Vector3] = []
	if radius <= 0.0:
		return local_positions

	var radius_sq := radius * radius
	for enemy in _enemy_registry:
		if enemy == null or enemy == self or not is_instance_valid(enemy):
			continue

		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() > radius_sq:
			continue

		local_positions.append(enemy.global_position)

	return local_positions


func _compute_crowd_pressure(local_enemy_positions: Array[Vector3]) -> float:
	if crowd_chain_neighbor_radius <= 0.0 or local_enemy_positions.is_empty():
		return 0.0

	var pressure := 0.0
	var neighbor_radius_sq := crowd_chain_neighbor_radius * crowd_chain_neighbor_radius
	for enemy_position in local_enemy_positions:
		var offset := enemy_position - global_position
		offset.y = 0.0
		var distance_sq := offset.length_squared()
		if distance_sq >= neighbor_radius_sq:
			continue

		var distance_to_enemy := sqrt(distance_sq)
		pressure += 1.0 - (distance_to_enemy / crowd_chain_neighbor_radius)

	return clampf(pressure, 0.0, 1.0)


# Locomotion and fallback
func _face_position(target_position: Vector3, delta: float) -> void:
	var face_offset := target_position - global_position
	face_offset.y = 0.0
	if face_offset.length_squared() <= 0.0001:
		return

	var target_yaw := atan2(face_offset.x, face_offset.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)


func apply_player_collision_push(push_direction: Vector3, player_position: Vector3, push_speed: float) -> void:
	_apply_player_collision_push_internal(push_direction, player_position, push_speed)


func _apply_player_collision_push_internal(push_direction: Vector3, player_position: Vector3, push_speed: float) -> void:
	var horizontal_push := push_direction
	horizontal_push.y = 0.0
	if horizontal_push.length_squared() <= 0.0001:
		return

	horizontal_push = horizontal_push.normalized()
	var away_direction := global_position - player_position
	away_direction.y = 0.0
	if away_direction.length_squared() > 0.0001:
		away_direction = away_direction.normalized()
	else:
		away_direction = horizontal_push

	var desired_direction := _choose_player_push_resolution_direction(away_direction, horizontal_push)
	if desired_direction.length_squared() <= 0.0001:
		return

	var capped_speed := clampf(push_speed, 0.0, player_collision_push_max_speed)
	if capped_speed <= 0.0:
		return

	var current_speed := _player_collision_push_velocity.length()
	_player_collision_push_velocity = desired_direction * maxf(current_speed, capped_speed)


func _choose_player_push_resolution_direction(away_direction: Vector3, push_direction: Vector3) -> Vector3:
	var local_enemy_positions := _get_cached_local_enemy_positions(player_push_block_neighbor_radius)
	var left_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var right_direction := -left_direction
	var left_penalty := _score_yield_direction_penalty(left_direction, local_enemy_positions)
	var right_penalty := _score_yield_direction_penalty(right_direction, local_enemy_positions)
	var lateral_direction := left_direction if left_penalty <= right_penalty else right_direction

	var outward_direction := away_direction
	if outward_direction.length_squared() <= 0.0001:
		outward_direction = push_direction

	var desired_direction := (
		lateral_direction * player_collision_push_lateral_weight +
		outward_direction * player_collision_push_outward_weight
	).normalized()
	if desired_direction.length_squared() > 0.0001:
		return desired_direction

	return outward_direction.normalized()


func _apply_player_collision_push(delta: float) -> bool:
	var push_velocity := _player_collision_push_velocity
	push_velocity.y = 0.0
	if push_velocity.length_squared() <= 0.0001:
		_player_collision_push_velocity = Vector3.ZERO
		return false

	var combined_velocity := Vector3(velocity.x, 0.0, velocity.z) + push_velocity
	var combined_speed := combined_velocity.length()
	var speed_cap := maxf(move_speed, player_collision_push_max_speed)
	if combined_speed > speed_cap and combined_speed > 0.0:
		combined_velocity = combined_velocity / combined_speed * speed_cap

	velocity.x = combined_velocity.x
	velocity.z = combined_velocity.z
	_player_collision_push_velocity = _player_collision_push_velocity.move_toward(
		Vector3.ZERO,
		player_collision_push_decay * delta
	)
	return true


func _update_stuck_state(delta: float, pre_move_position: Vector3, attempted_horizontal_move: bool) -> void:
	if _melee_state != MeleeCloseState.APPROACH:
		_stuck_elapsed = 0.0
		return

	if _nav_agent.is_navigation_finished() or not attempted_horizontal_move:
		_stuck_elapsed = 0.0
		return

	var horizontal_delta := global_position - pre_move_position
	horizontal_delta.y = 0.0

	if horizontal_delta.length() <= stuck_min_progress_distance:
		_stuck_elapsed += delta
	else:
		_stuck_elapsed = 0.0

	if _stuck_elapsed >= stuck_timeout:
		_stuck_elapsed = 0.0
		if _has_goal:
			_remember_failed_goal(_current_goal_position)
			_has_goal = false
			_goal_commit_remaining = 0.0
			_invalidate_navigation_cache()
		_recovery_elapsed = stuck_recovery_duration
		_recovery_sign *= -1.0


func _capture_melee_hold_runtime_debug(pre_move_position: Vector3, state_text: String, next_position: Vector3) -> void:
	_debug_hold_displacement = 0.0
	_debug_hold_velocity = 0.0
	_debug_hold_collision_count = 0
	_debug_hold_collision_names.clear()
	_debug_hold_has_yield = _debug_yield_speed > 0.01

	if _melee_state != MeleeCloseState.MELEE_HOLD:
		return

	var horizontal_delta := global_position - pre_move_position
	horizontal_delta.y = 0.0
	_debug_hold_displacement = horizontal_delta.length()
	_debug_hold_velocity = Vector2(velocity.x, velocity.z).length()
	_debug_hold_collision_count = get_slide_collision_count()
	for collision_index in range(_debug_hold_collision_count):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue

		var collider := collision.get_collider()
		if collider == null:
			_debug_hold_collision_names.append("<null>")
			continue

		if collider is Node:
			_debug_hold_collision_names.append((collider as Node).name)
		else:
			_debug_hold_collision_names.append(str(collider))

	_maybe_append_melee_hold_debug_log(state_text, next_position)


func _prepare_melee_hold_debug_log() -> void:
	if not melee_hold_debug_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(MELEE_HOLD_DEBUG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- melee hold debug session start ---")
	file.flush()
	_last_melee_hold_log_msec = Time.get_ticks_msec()


func _maybe_append_melee_hold_debug_log(state_text: String, next_position: Vector3) -> void:
	if not melee_hold_debug_enabled:
		return

	var should_log := _debug_hold_displacement >= MELEE_HOLD_DISPLACEMENT_LOG_THRESHOLD
	should_log = should_log or _debug_hold_collision_count > 0
	should_log = should_log or _debug_hold_has_yield
	if not should_log:
		return

	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_melee_hold_log_msec < MELEE_HOLD_DEBUG_INTERVAL_MSEC:
		return

	_last_melee_hold_log_msec = now_msec
	var file := FileAccess.open(MELEE_HOLD_DEBUG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	var distance_to_target := _horizontal_distance_to(_target_node.global_position) if _target_node != null else -1.0
	var hold_limit := melee_engage_distance + engage_hold_tolerance
	var hold_margin := hold_limit - distance_to_target if distance_to_target >= 0.0 else -1.0
	file.seek_end()
	file.store_line(
		"%s | enemy=%s | state=%s | pos=(%.2f, %.2f, %.2f) | d_target=%.3f | hold_margin=%.3f | disp=%.4f | vel=%.3f | yield=%s | yield_speed=%.3f | yield_direct=%.3f | yield_chain=%.3f | collisions=%d | colliders=%s | next=(%.2f, %.2f, %.2f) | nav_refresh=%s | path_pts=%d | goal=%s | goal_at=(%.2f, %.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			state_text,
			global_position.x,
			global_position.y,
			global_position.z,
			distance_to_target,
			hold_margin,
			_debug_hold_displacement,
			_debug_hold_velocity,
			str(_debug_hold_has_yield),
			_debug_yield_speed,
			_debug_yield_direct_pressure,
			_debug_yield_chain_pressure,
			_debug_hold_collision_count,
			",".join(_debug_hold_collision_names),
			next_position.x,
			next_position.y,
			next_position.z,
			str(_debug_nav_cache_refreshed),
			_nav_agent.get_current_navigation_path().size(),
			str(_has_goal),
			_current_goal_position.x,
			_current_goal_position.y,
			_current_goal_position.z,
		]
	)
	file.flush()


# Debug presentation and logging
func _update_debug(state_text: String, next_position: Vector3, iteration_id: int) -> void:
	var distance_to_target := -1.0
	var distance_to_next: float = _horizontal_distance(global_position, next_position)
	if _target_node != null:
		distance_to_target = _horizontal_distance(global_position, _target_node.global_position)

	_refresh_label_if_needed(state_text, next_position, iteration_id, distance_to_target, distance_to_next)
	_update_nav_path_debug_if_needed()

	if not debug_enabled:
		return

	_maybe_append_debug_log(state_text, next_position, iteration_id, distance_to_target, distance_to_next)


func _refresh_label_if_needed(
	state_text: String,
	next_position: Vector3,
	iteration_id: int,
	distance_to_target: float = -1.0,
	distance_to_next: float = 0.0
) -> void:
	if _debug_label == null:
		return

	var show_global_debug := _is_enemy_status_enabled()
	_debug_label.visible = show_global_debug
	if not show_global_debug:
		return

	if _debug_label_refresh_remaining > 0.0:
		return

	_debug_label_refresh_remaining = DEBUG_LABEL_REFRESH_INTERVAL_SEC
	_refresh_label(state_text, next_position, iteration_id, distance_to_target, distance_to_next)


func _refresh_label(
	state_text: String,
	next_position: Vector3,
	iteration_id: int,
	distance_to_target: float = -1.0,
	distance_to_next: float = 0.0
) -> void:
	var profile_start_usec := _profile_start_usec()
	if _debug_label == null:
		_record_profile_duration("label", Time.get_ticks_usec() - profile_start_usec)
		return

	var lines: Array[String] = []
	if show_hp_label:
		lines.append("HP: %.0f/%.0f" % [_current_hp, max_hp])

	if debug_enabled:
		lines.append_array([
			"close_state: %s" % _get_melee_state_name(),
			"state_age: %.2f" % _melee_state_age,
			"state_changes: %d" % _melee_state_transition_count,
			"state: %s" % state_text,
			"iter: %d" % iteration_id,
			"goal: %s" % str(_has_goal),
			"goal_age: %.2f" % _goal_age,
			"path_pts: %d" % _nav_agent.get_current_navigation_path().size(),
			"stuck: %.2f" % _stuck_elapsed,
			"d_target: %.2f" % distance_to_target,
			"d_next: %.2f" % distance_to_next,
			"next: %.2f, %.2f" % [next_position.x, next_position.z],
		])
		if _has_goal:
			lines.append("goal_at: %.2f, %.2f" % [_current_goal_position.x, _current_goal_position.z])
			lines.append("goal_dbg: c=%d rp=%d rf=%d fb=%s pe=%.2f ge=%.2f" % [
				_debug_goal_candidate_count,
				_debug_goal_rejected_projection_count,
				_debug_goal_rejected_failed_count,
				str(_debug_goal_used_fallback),
				_debug_goal_projection_error,
				_debug_goal_path_end_error,
			])
		if _debug_yield_speed > 0.0 or _debug_yield_neighbor_count > 0:
			lines.append("yield: %.2f str=%.2f n=%d p=%.2f c=%.2f dp=%.2f cp=%.2f" % [
				_debug_yield_speed,
				_debug_yield_strength,
				_debug_yield_neighbor_count,
				_debug_yield_penalty,
				_debug_crowd_pressure,
				_debug_yield_direct_pressure,
				_debug_yield_chain_pressure,
			])
		if _melee_state == MeleeCloseState.CLOSE_ADJUST:
			lines.append("cadj: pd=%.2f gap=%.2f cp=%.2f nav=%s" % [
				_debug_close_adjust_path_distance,
				_debug_close_adjust_target_gap,
				_debug_close_adjust_crowd_pressure,
				str(_debug_nav_cache_refreshed),
			])
			lines.append("cadj: L=%.2f R=%.2f side=%.0f lat=%.2f spd=%.2f" % [
				_debug_close_adjust_left_penalty,
				_debug_close_adjust_right_penalty,
				_debug_close_adjust_side_sign,
				_debug_close_adjust_lateral_weight,
				_debug_close_adjust_move_speed,
			])
		if _melee_state == MeleeCloseState.MELEE_HOLD:
			lines.append("hold: disp=%.4f vel=%.2f y=%s col=%d" % [
				_debug_hold_displacement,
				_debug_hold_velocity,
				str(_debug_hold_has_yield),
				_debug_hold_collision_count,
			])
			if not _debug_hold_collision_names.is_empty():
				lines.append("hold_col: %s" % ",".join(_debug_hold_collision_names))

	_debug_label.text = "\n".join(lines)
	_record_profile_duration("label", Time.get_ticks_usec() - profile_start_usec)


func _update_nav_path_debug_if_needed() -> void:
	if _nav_path_debug == null or _nav_path_mesh == null:
		return

	if not _is_enemy_nav_path_enabled():
		if _nav_path_debug.visible or _nav_path_mesh.get_surface_count() > 0:
			_clear_nav_path_debug()
		return

	if _nav_debug_refresh_remaining > 0.0:
		return

	_nav_debug_refresh_remaining = NAV_DEBUG_REFRESH_INTERVAL_SEC
	_update_nav_path_debug()


func _update_nav_path_debug() -> void:
	var profile_start_usec := _profile_start_usec()
	_nav_path_mesh.clear_surfaces()
	_draw_current_path()
	_draw_goal_marker()
	_draw_candidate_ring()
	_nav_path_debug.visible = _nav_path_mesh.get_surface_count() > 0
	_record_profile_duration("nav_debug", Time.get_ticks_usec() - profile_start_usec)


func _get_navigation_next_position(move_target: Vector3, distance_to_target: float) -> Vector3:
	_debug_nav_cache_refreshed = false
	if _should_refresh_navigation_cache(move_target, distance_to_target):
		_nav_agent.target_position = move_target
		_cached_nav_next_position = _resolve_navigation_next_position(move_target)
		_cached_nav_move_target = move_target
		_nav_refresh_remaining = _compute_nav_refresh_interval(distance_to_target)
		_debug_nav_cache_refreshed = true

	return _cached_nav_next_position if _cached_nav_next_position != Vector3.ZERO else move_target


func _should_refresh_navigation_cache(move_target: Vector3, distance_to_target: float) -> bool:
	if _cached_nav_move_target == INVALID_POINT:
		return true

	if _nav_refresh_remaining <= 0.0:
		return true

	if _horizontal_distance(_cached_nav_move_target, move_target) > 0.05:
		return true

	if _recovery_elapsed > 0.0:
		return true

	if _melee_state == MeleeCloseState.APPROACH and distance_to_target <= nav_refresh_far_distance:
		return true

	return false


func _compute_nav_refresh_interval(distance_to_target: float) -> float:
	if _melee_state == MeleeCloseState.CLOSE_ADJUST:
		return maxf(close_adjust_nav_refresh_interval, 0.0)

	if distance_to_target <= nav_refresh_far_distance:
		return nav_refresh_interval_near

	return nav_refresh_interval_far


func _invalidate_navigation_cache() -> void:
	_nav_refresh_remaining = 0.0
	_cached_nav_next_position = Vector3.ZERO
	_cached_nav_move_target = INVALID_POINT


func _capture_goal_path_debug() -> void:
	var path: PackedVector3Array = _nav_agent.get_current_navigation_path()
	if path.is_empty():
		_debug_goal_path_end = Vector3.ZERO
		_debug_goal_path_end_error = 0.0
		return

	_debug_goal_path_end = path[path.size() - 1]
	_debug_goal_path_end_error = _horizontal_distance(_debug_goal_path_end, _current_goal_position)


func _draw_current_path() -> void:
	var path: PackedVector3Array = _nav_agent.get_current_navigation_path()
	if path.size() == 0:
		return

	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _path_debug_material)
	_nav_path_mesh.surface_set_color(_path_debug_material.albedo_color)
	_nav_path_mesh.surface_add_vertex(Vector3.UP * 0.15)
	for path_point in path:
		_nav_path_mesh.surface_add_vertex(to_local(path_point + Vector3.UP * 0.15))
	_nav_path_mesh.surface_end()


func _resolve_navigation_next_position(move_target: Vector3) -> Vector3:
	var profile_start_usec := _profile_start_usec()
	var next_position := _nav_agent.get_next_path_position()
	var horizontal_offset := next_position - global_position
	horizontal_offset.y = 0.0
	if horizontal_offset.length_squared() > 0.04:
		_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
		return next_position

	var path := _nav_agent.get_current_navigation_path()
	for path_point in path:
		var path_offset := path_point - global_position
		path_offset.y = 0.0
		if path_offset.length_squared() > 0.04:
			_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
			return path_point

	_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
	return move_target


func _draw_goal_marker() -> void:
	if not _has_goal:
		return

	var local_goal := to_local(_current_goal_position + Vector3.UP * 0.2)
	var marker_extent := 0.18

	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _goal_debug_material)
	_nav_path_mesh.surface_set_color(_goal_debug_material.albedo_color)
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(-marker_extent, 0.0, 0.0))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(marker_extent, 0.0, 0.0))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(0.0, 0.0, -marker_extent))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(0.0, 0.0, marker_extent))
	_nav_path_mesh.surface_end()


func _draw_candidate_ring() -> void:
	if _debug_candidate_positions.size() < 2:
		return

	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _candidate_debug_material)
	_nav_path_mesh.surface_set_color(_candidate_debug_material.albedo_color)
	for candidate_position in _debug_candidate_positions:
		_nav_path_mesh.surface_add_vertex(to_local(candidate_position + Vector3.UP * 0.1))

	_nav_path_mesh.surface_add_vertex(to_local(_debug_candidate_positions[0] + Vector3.UP * 0.1))
	_nav_path_mesh.surface_end()


func _should_capture_candidate_debug() -> bool:
	return debug_enabled and _is_enemy_nav_path_enabled()


func _build_debug_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	return material


func _clear_nav_path_debug() -> void:
	if _nav_path_mesh != null:
		_nav_path_mesh.clear_surfaces()

	if _nav_path_debug != null:
		_nav_path_debug.visible = false


func _get_debug_overlay() -> Node:
	if _debug_overlay_cache != null and is_instance_valid(_debug_overlay_cache):
		return _debug_overlay_cache

	_debug_overlay_cache = get_tree().get_first_node_in_group("debug_overlay")
	return _debug_overlay_cache


func _is_enemy_status_enabled() -> bool:
	var debug_overlay := _get_debug_overlay()
	if debug_overlay != null and debug_overlay.has_method("is_enemy_status_enabled"):
		return debug_overlay.is_enemy_status_enabled()

	return true


func _is_enemy_nav_path_enabled() -> bool:
	var debug_overlay := _get_debug_overlay()
	if debug_overlay != null and debug_overlay.has_method("is_enemy_nav_path_enabled"):
		return debug_overlay.is_enemy_nav_path_enabled()

	return false


func _prepare_debug_log() -> void:
	if not debug_enabled or not debug_log_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- enemy debug session start ---")
	file.flush()


func _maybe_append_debug_log(
	state_text: String,
	next_position: Vector3,
	iteration_id: int,
	distance_to_target: float,
	distance_to_next: float
) -> void:
	if not debug_log_enabled:
		return

	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_debug_write_msec < DEBUG_WRITE_INTERVAL_MSEC:
		return

	_last_debug_write_msec = now_msec

	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line(
		"%s | enemy=%s | pos=(%.2f, %.2f, %.2f) | close_state=%s | close_state_age=%.2f | close_state_changes=%d | state=%s | iter=%d | goal=%s | goal_at=(%.2f, %.2f, %.2f) | path_pts=%d | goal_candidates=%d | goal_reject_proj=%d | goal_reject_failed=%d | goal_fallback=%s | goal_raw=(%.2f, %.2f, %.2f) | goal_proj=(%.2f, %.2f, %.2f) | goal_proj_err=%.2f | path_end=(%.2f, %.2f, %.2f) | path_end_err=%.2f | d_target=%.2f | d_next=%.2f | next=(%.2f, %.2f, %.2f) | nav_refresh=%s | cadj_path_dist=%.2f | cadj_gap=%.2f | cadj_crowd=%.2f | cadj_left=%.2f | cadj_right=%.2f | cadj_side=%.0f | cadj_lat=%.2f | cadj_speed=%.2f | yield_speed=%.2f | yield_strength=%.2f | yield_neighbors=%d | yield_penalty=%.2f | crowd_pressure=%.2f | yield_direct=%.2f | yield_chain=%.2f | yield_dir=(%.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			global_position.x,
			global_position.y,
			global_position.z,
			_get_melee_state_name(),
			_melee_state_age,
			_melee_state_transition_count,
			state_text,
			iteration_id,
			str(_has_goal),
			_current_goal_position.x,
			_current_goal_position.y,
			_current_goal_position.z,
			_nav_agent.get_current_navigation_path().size(),
			_debug_goal_candidate_count,
			_debug_goal_rejected_projection_count,
			_debug_goal_rejected_failed_count,
			str(_debug_goal_used_fallback),
			_debug_goal_raw_candidate.x,
			_debug_goal_raw_candidate.y,
			_debug_goal_raw_candidate.z,
			_debug_goal_projected_candidate.x,
			_debug_goal_projected_candidate.y,
			_debug_goal_projected_candidate.z,
			_debug_goal_projection_error,
			_debug_goal_path_end.x,
			_debug_goal_path_end.y,
			_debug_goal_path_end.z,
			_debug_goal_path_end_error,
			distance_to_target,
			distance_to_next,
			next_position.x,
			next_position.y,
			next_position.z,
			str(_debug_nav_cache_refreshed),
			_debug_close_adjust_path_distance,
			_debug_close_adjust_target_gap,
			_debug_close_adjust_crowd_pressure,
			_debug_close_adjust_left_penalty,
			_debug_close_adjust_right_penalty,
			_debug_close_adjust_side_sign,
			_debug_close_adjust_lateral_weight,
			_debug_close_adjust_move_speed,
			_debug_yield_speed,
			_debug_yield_strength,
			_debug_yield_neighbor_count,
			_debug_yield_penalty,
			_debug_crowd_pressure,
			_debug_yield_direct_pressure,
			_debug_yield_chain_pressure,
			_debug_yield_direction.x,
			_debug_yield_direction.z,
		]
	)
	file.flush()


func _reset_yield_debug_state() -> void:
	_debug_yield_speed = 0.0
	_debug_yield_strength = 0.0
	_debug_yield_neighbor_count = 0
	_debug_yield_penalty = 0.0
	_debug_yield_direction = Vector3.ZERO
	_debug_crowd_pressure = 0.0
	_debug_yield_direct_pressure = 0.0
	_debug_yield_chain_pressure = 0.0


func _reset_close_adjust_debug_state() -> void:
	_debug_nav_cache_refreshed = false
	_debug_close_adjust_path_distance = 0.0
	_debug_close_adjust_target_gap = 0.0
	_debug_close_adjust_crowd_pressure = 0.0
	_debug_close_adjust_left_penalty = 0.0
	_debug_close_adjust_right_penalty = 0.0
	_debug_close_adjust_side_sign = 0.0
	_debug_close_adjust_lateral_weight = 0.0
	_debug_close_adjust_move_speed = 0.0


func _reset_goal_debug_state() -> void:
	_debug_goal_candidate_count = 0
	_debug_goal_rejected_projection_count = 0
	_debug_goal_rejected_failed_count = 0
	_debug_goal_used_fallback = false
	_debug_goal_raw_candidate = Vector3.ZERO
	_debug_goal_projected_candidate = Vector3.ZERO
	_debug_goal_projection_error = 0.0
	_debug_goal_path_end = Vector3.ZERO
	_debug_goal_path_end_error = 0.0


# Utility helpers
static func set_profiling_enabled(enabled: bool) -> void:
	_profiling_enabled = enabled
	_reset_profile_accumulators()


static func get_profile_snapshot() -> Dictionary:
	if _profile_window_start_usec <= 0:
		return {}

	var now_usec: int = Time.get_ticks_usec()
	var window_usec: int = maxi(now_usec - _profile_window_start_usec, 1)
	var physics_total_ms: float = float(_profile_physics_total_usec) / 1000.0
	return {
		"window_sec": float(window_usec) / 1000000.0,
		"enemy_count": _enemy_registry.size(),
		"physics_total_ms": physics_total_ms,
		"physics_avg_ms": physics_total_ms / maxf(float(_profile_physics_calls), 1.0),
		"physics_calls": _profile_physics_calls,
		"goal_total_ms": float(_profile_goal_total_usec) / 1000.0,
		"goal_calls": _profile_goal_calls,
		"goal_share": _safe_profile_share(_profile_goal_total_usec, _profile_physics_total_usec),
		"yield_total_ms": float(_profile_yield_total_usec) / 1000.0,
		"yield_calls": _profile_yield_calls,
		"yield_share": _safe_profile_share(_profile_yield_total_usec, _profile_physics_total_usec),
		"label_total_ms": float(_profile_label_total_usec) / 1000.0,
		"label_share": _safe_profile_share(_profile_label_total_usec, _profile_physics_total_usec),
		"nav_debug_total_ms": float(_profile_nav_debug_total_usec) / 1000.0,
		"nav_debug_share": _safe_profile_share(_profile_nav_debug_total_usec, _profile_physics_total_usec),
		"nav_query_total_ms": float(_profile_nav_query_total_usec) / 1000.0,
		"nav_query_share": _safe_profile_share(_profile_nav_query_total_usec, _profile_physics_total_usec),
		"move_slide_total_ms": float(_profile_move_slide_total_usec) / 1000.0,
		"move_slide_share": _safe_profile_share(_profile_move_slide_total_usec, _profile_physics_total_usec),
	}


static func _safe_profile_share(part_usec: int, total_usec: int) -> float:
	if total_usec <= 0:
		return 0.0

	return float(part_usec) / float(total_usec)


static func _reset_profile_accumulators() -> void:
	_profile_window_start_usec = Time.get_ticks_usec() if _profiling_enabled else 0
	_profile_physics_total_usec = 0
	_profile_goal_total_usec = 0
	_profile_yield_total_usec = 0
	_profile_label_total_usec = 0
	_profile_nav_debug_total_usec = 0
	_profile_nav_query_total_usec = 0
	_profile_move_slide_total_usec = 0
	_profile_physics_calls = 0
	_profile_goal_calls = 0
	_profile_yield_calls = 0


func _profile_start_usec() -> int:
	if not _profiling_enabled:
		return 0

	if _profile_window_start_usec <= 0:
		_profile_window_start_usec = Time.get_ticks_usec()

	return Time.get_ticks_usec()


func _record_profile_duration(section: String, duration_usec: int) -> void:
	if not _profiling_enabled:
		return

	if _profile_window_start_usec <= 0:
		_profile_window_start_usec = Time.get_ticks_usec()

	match section:
		"physics":
			_profile_physics_total_usec += duration_usec
			_profile_physics_calls += 1
		"goal":
			_profile_goal_total_usec += duration_usec
			_profile_goal_calls += 1
		"yield":
			_profile_yield_total_usec += duration_usec
			_profile_yield_calls += 1
		"label":
			_profile_label_total_usec += duration_usec
		"nav_debug":
			_profile_nav_debug_total_usec += duration_usec
		"nav_query":
			_profile_nav_query_total_usec += duration_usec
		"move_slide":
			_profile_move_slide_total_usec += duration_usec


func _horizontal_distance_to(target_position: Vector3) -> float:
	return _horizontal_distance(global_position, target_position)


func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()


func _has_valid_target() -> bool:
	return _target_node != null and is_instance_valid(_target_node)


func apply_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	if _current_hp <= 0.0:
		queue_free()


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	_refresh_label("idle", Vector3.ZERO, 0)


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)
