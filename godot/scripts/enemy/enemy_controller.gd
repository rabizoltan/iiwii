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

# Movement and targeting
@export var move_speed: float = 4.5
@export var turn_speed: float = 8.0
@export var target_path: NodePath

# Debug and health
@export var debug_enabled: bool = true
@export var debug_log_enabled: bool = false
@export var show_hp_label: bool = true
@export var max_hp: float = 3.0

# Melee engage behavior
@export var melee_engage_distance: float = 1.8
@export var engage_hold_tolerance: float = 0.35

# Player-vs-crowd pressure response
@export var player_push_yield_distance: float = 1.2
@export var player_push_yield_speed: float = 4.2
@export var player_push_side_yield_weight: float = 1.0
@export var player_push_block_check_distance: float = 0.8
@export var player_push_block_neighbor_radius: float = 1.8
@export var player_push_min_yield_factor: float = 0.6
@export var crowd_chain_yield_distance: float = 2.2
@export var crowd_chain_neighbor_radius: float = 1.1
@export var crowd_chain_yield_bonus: float = 1.1
@export var local_enemy_cache_interval: float = 0.12

# Goal selection
@export var goal_commit_duration: float = 0.6
@export var goal_reacquire_distance: float = 0.9
@export var engage_candidate_count: int = 10
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
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0
var _nav_path_mesh: ImmediateMesh
var _has_goal: bool = false
var _current_goal_position: Vector3 = Vector3.ZERO
var _goal_center_at_selection: Vector3 = Vector3.ZERO
var _goal_commit_remaining: float = 0.0
var _goal_age: float = 0.0
var _recent_failed_goals: Array[Vector3] = []
var _debug_candidate_positions: PackedVector3Array = PackedVector3Array()
var _local_enemy_cache_positions: Array[Vector3] = []
var _local_enemy_cache_radius: float = 0.0
var _local_enemy_cache_remaining: float = 0.0
var _nav_refresh_remaining: float = 0.0
var _cached_nav_next_position: Vector3 = Vector3.ZERO
var _cached_nav_move_target: Vector3 = Vector3(INF, INF, INF)
var _debug_yield_speed: float = 0.0
var _debug_yield_strength: float = 0.0
var _debug_yield_neighbor_count: int = 0
var _debug_yield_penalty: float = 0.0
var _debug_yield_direction: Vector3 = Vector3.ZERO
var _debug_crowd_pressure: float = 0.0
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
const DEBUG_WRITE_INTERVAL_MSEC := 500
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
	_refresh_label("idle", Vector3.ZERO, 0)


func _resolve_target() -> void:
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

	if _goal_commit_remaining > 0.0:
		_goal_commit_remaining = maxf(_goal_commit_remaining - delta, 0.0)

	if _local_enemy_cache_remaining > 0.0:
		_local_enemy_cache_remaining = maxf(_local_enemy_cache_remaining - delta, 0.0)

	if _nav_refresh_remaining > 0.0:
		_nav_refresh_remaining = maxf(_nav_refresh_remaining - delta, 0.0)

	if _debug_label_refresh_remaining > 0.0:
		_debug_label_refresh_remaining = maxf(_debug_label_refresh_remaining - delta, 0.0)

	if _nav_debug_refresh_remaining > 0.0:
		_nav_debug_refresh_remaining = maxf(_nav_debug_refresh_remaining - delta, 0.0)

	if _has_goal:
		_goal_age += delta
	else:
		_goal_age = 0.0

	if _target_node == null:
		_resolve_target()

	if _target_node == null:
		velocity.x = 0.0
		velocity.z = 0.0
		debug_state = "no target"
	else:
		var distance_to_target: float = _horizontal_distance_to(_target_node.global_position)
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

		if _should_refresh_goal():
			_select_engage_goal()

		if _is_in_engage_hold(distance_to_target):
			var yield_velocity := _compute_player_yield_velocity()
			if yield_velocity != Vector3.ZERO:
				velocity.x = yield_velocity.x
				velocity.z = yield_velocity.z
				attempted_horizontal_move = true
				debug_state = "yielding"
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				debug_state = "holding"
			_face_position(_target_node.global_position, delta)
			debug_next_position = _current_goal_position if _has_goal else global_position
		else:
			var move_target: Vector3 = _current_goal_position if _has_goal else _target_node.global_position
			var next_position := _get_navigation_next_position(move_target, distance_to_target)
			debug_next_position = next_position
			var horizontal_offset: Vector3 = next_position - global_position
			horizontal_offset.y = 0.0

			if _nav_agent.is_navigation_finished():
				velocity.x = 0.0
				velocity.z = 0.0
				_face_position(_target_node.global_position, delta)
				debug_state = "arrived"
			elif horizontal_offset.length_squared() > 0.04:
				var move_direction: Vector3 = horizontal_offset.normalized()
				if _recovery_elapsed > 0.0:
					var recovery_tangent := Vector3(-move_direction.z, 0.0, move_direction.x) * _recovery_sign
					move_direction = (move_direction * 0.25 + recovery_tangent).normalized()
					_recovery_elapsed = maxf(_recovery_elapsed - delta, 0.0)
					debug_state = "recovering"
				else:
					debug_state = "moving"

				velocity.x = move_direction.x * move_speed
				velocity.z = move_direction.z * move_speed
				attempted_horizontal_move = true
				_face_position(global_position + move_direction, delta)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				_face_position(_target_node.global_position, delta)
				debug_state = "at next point"

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var move_slide_start_usec := _profile_start_usec()
	move_and_slide()
	_record_profile_duration("move_slide", Time.get_ticks_usec() - move_slide_start_usec)
	_update_stuck_state(delta, pre_move_position, attempted_horizontal_move)
	_update_debug(debug_state, debug_next_position, debug_iteration_id)
	_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)


# Goal selection and candidate scoring
func _should_refresh_goal() -> bool:
	if _target_node == null:
		return false

	if not _has_goal:
		return true

	var distance_to_target := _horizontal_distance_to(_target_node.global_position)
	if _is_in_engage_hold(distance_to_target):
		return false

	if _goal_commit_remaining > 0.0:
		return false

	var target_shift := _horizontal_distance(_goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return true

	var goal_distance := _horizontal_distance(global_position, _current_goal_position)
	return goal_distance <= engage_hold_tolerance


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
	var center := Vector3(target_position.x, global_position.y, target_position.z)
	var candidate_positions := PackedVector3Array()
	var capture_candidate_debug := _should_capture_candidate_debug()
	var nearby_enemy_positions := _collect_nearby_enemy_positions(center)
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

		var score := _score_candidate(projected_candidate, nearby_enemy_positions)
		if score < best_score:
			best_score = score
			_debug_goal_raw_candidate = raw_candidate
			_debug_goal_projected_candidate = projected_candidate
			_debug_goal_projection_error = _horizontal_distance(raw_candidate, projected_candidate)
			best_candidate = projected_candidate

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

func _score_candidate(candidate: Vector3, nearby_enemy_positions: Array[Vector3]) -> float:
	var movement_score := _horizontal_distance(global_position, candidate)
	var spread_score := _score_spread_penalty(candidate, nearby_enemy_positions)
	return movement_score + spread_score


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


func _is_in_engage_hold(distance_to_target: float) -> bool:
	return distance_to_target <= melee_engage_distance + engage_hold_tolerance


# Crowd-pressure response
func _compute_player_yield_velocity() -> Vector3:
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

	var chain_pressure: float = 0.0
	if crowd_chain_yield_distance > player_push_yield_distance and distance_to_target < crowd_chain_yield_distance:
		var chain_ratio := 1.0 - clampf(
			(distance_to_target - player_push_yield_distance) / (crowd_chain_yield_distance - player_push_yield_distance),
			0.0,
			1.0
		)
		chain_pressure = crowd_pressure * chain_ratio

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


func _update_stuck_state(delta: float, pre_move_position: Vector3, attempted_horizontal_move: bool) -> void:
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
			lines.append("yield: %.2f str=%.2f n=%d p=%.2f c=%.2f" % [
				_debug_yield_speed,
				_debug_yield_strength,
				_debug_yield_neighbor_count,
				_debug_yield_penalty,
				_debug_crowd_pressure,
			])

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
	if _should_refresh_navigation_cache(move_target, distance_to_target):
		_nav_agent.target_position = move_target
		_cached_nav_next_position = _resolve_navigation_next_position(move_target)
		_cached_nav_move_target = move_target
		_nav_refresh_remaining = _compute_nav_refresh_interval(distance_to_target)

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

	if distance_to_target <= nav_refresh_far_distance:
		return true

	return false


func _compute_nav_refresh_interval(distance_to_target: float) -> float:
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
		"%s | enemy=%s | pos=(%.2f, %.2f, %.2f) | state=%s | iter=%d | goal=%s | goal_at=(%.2f, %.2f, %.2f) | path_pts=%d | goal_candidates=%d | goal_reject_proj=%d | goal_reject_failed=%d | goal_fallback=%s | goal_raw=(%.2f, %.2f, %.2f) | goal_proj=(%.2f, %.2f, %.2f) | goal_proj_err=%.2f | path_end=(%.2f, %.2f, %.2f) | path_end_err=%.2f | d_target=%.2f | d_next=%.2f | next=(%.2f, %.2f, %.2f) | yield_speed=%.2f | yield_strength=%.2f | yield_neighbors=%d | yield_penalty=%.2f | crowd_pressure=%.2f | yield_dir=(%.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			global_position.x,
			global_position.y,
			global_position.z,
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
			_debug_yield_speed,
			_debug_yield_strength,
			_debug_yield_neighbor_count,
			_debug_yield_penalty,
			_debug_crowd_pressure,
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


func apply_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	if _current_hp <= 0.0:
		queue_free()


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	_refresh_label("idle", Vector3.ZERO, 0)


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)
