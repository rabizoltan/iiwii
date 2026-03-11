extends CharacterBody3D

enum MeleeState {
	APPROACH,
	CLOSE_ADJUST,
	MELEE_HOLD,
}

@export var move_speed: float = 4.5
@export var close_adjust_speed_scale: float = 0.45
@export var turn_speed: float = 8.0
@export var target_path: NodePath
@export var debug_enabled: bool = true
@export var show_hp_label: bool = true
@export var max_hp: float = 3.0
@export var desired_stop_distance: float = 1.35
@export var hold_exit_buffer: float = 0.4
@export var close_adjust_band: float = 0.8
@export var goal_commit_time: float = 0.75
@export var goal_refresh_min_interval: float = 0.6
@export var target_move_replan_distance: float = 0.8
@export var melee_ring_candidates: int = 8
@export var nav_projection_tolerance: float = 1.0
@export var nav_waypoint_min_offset: float = 0.15
@export var stuck_timeout: float = 0.35
@export var stuck_recovery_duration: float = 0.3
@export var stuck_min_progress_distance: float = 0.02

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _debug_label: Label3D = $DebugLabel3D
@onready var _nav_path_debug: MeshInstance3D = $NavPathDebug

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_node: Node3D
var _last_debug_write_msec: int = 0
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0
var _nav_path_mesh: ImmediateMesh
var _state: MeleeState = MeleeState.APPROACH
var _selected_goal_position: Vector3 = Vector3.ZERO
var _has_selected_goal: bool = false
var _goal_age: float = 0.0
var _goal_refresh_elapsed: float = 0.0
var _last_goal_reason: String = "init"
var _last_goal_failure_reason: String = "none"
var _last_motion_reason: String = "init"
var _last_target_anchor: Vector3 = Vector3.ZERO
var _state_change_count: int = 0
var _goal_change_count: int = 0

const DEBUG_LOG_PATH := "user://debug/enemy_debug.log"
const MOVEMENT_DEBUG_LOG_PATH := "user://debug/enemy_movement_debug.txt"
const DEBUG_WRITE_INTERVAL_MSEC := 500


func _ready() -> void:
	_current_hp = max_hp
	_nav_path_mesh = ImmediateMesh.new()
	_nav_path_debug.mesh = _nav_path_mesh
	_nav_agent.set_navigation_map(get_world_3d().navigation_map)
	_nav_agent.path_desired_distance = 0.35
	_nav_agent.target_desired_distance = 0.2
	call_deferred("_resolve_target")
	_prepare_debug_log()
	_refresh_label("idle", Vector3.ZERO, 0)


func _resolve_target() -> void:
	if not target_path.is_empty():
		_target_node = get_node_or_null(target_path) as Node3D

	if _target_node == null:
		_target_node = get_tree().get_first_node_in_group("player") as Node3D

	if _target_node != null and _last_target_anchor == Vector3.ZERO:
		_last_target_anchor = _get_target_floor_position()


func _physics_process(delta: float) -> void:
	var pre_move_position := global_position
	var debug_state := "idle"
	var debug_next_position := Vector3.ZERO
	var debug_iteration_id := 0
	var attempted_horizontal_move := false

	if _target_node == null:
		_resolve_target()

	if _target_node == null:
		velocity.x = 0.0
		velocity.z = 0.0
		debug_state = "no target"
		_last_motion_reason = "no_target"
	else:
		var iteration_id := NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map())
		debug_iteration_id = iteration_id
		if iteration_id == 0:
			velocity.x = 0.0
			velocity.z = 0.0
			debug_state = "nav not ready"
			_last_motion_reason = "nav_not_ready"
			_update_debug(debug_state, debug_next_position, debug_iteration_id)
			move_and_slide()
			return

		_goal_age += delta
		_goal_refresh_elapsed += delta

		var distance_to_target := _get_horizontal_distance_to_target()
		var next_state := _choose_melee_state(distance_to_target)
		if next_state != _state:
			_transition_state(next_state, distance_to_target)

		match _state:
			MeleeState.APPROACH:
				debug_state = _run_approach(delta)
				attempted_horizontal_move = velocity.length_squared() > 0.001
				debug_next_position = _selected_goal_position if _has_selected_goal else Vector3.ZERO
			MeleeState.CLOSE_ADJUST:
				debug_state = _run_close_adjust(delta, distance_to_target)
				attempted_horizontal_move = velocity.length_squared() > 0.001
			MeleeState.MELEE_HOLD:
				debug_state = _run_melee_hold()

		_face_target(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_stuck_state(delta, pre_move_position, attempted_horizontal_move)
	_update_debug(debug_state, debug_next_position, debug_iteration_id)


func _choose_melee_state(distance_to_target: float) -> MeleeState:
	if _is_inside_hold_envelope(distance_to_target):
		return MeleeState.MELEE_HOLD
	if distance_to_target <= desired_stop_distance + close_adjust_band:
		return MeleeState.CLOSE_ADJUST
	return MeleeState.APPROACH


func _is_inside_hold_envelope(distance_to_target: float) -> bool:
	var hold_exit_distance := desired_stop_distance + hold_exit_buffer
	if _state == MeleeState.MELEE_HOLD:
		return distance_to_target <= hold_exit_distance
	return distance_to_target <= desired_stop_distance


func _transition_state(next_state: MeleeState, distance_to_target: float) -> void:
	_state = next_state
	_state_change_count += 1
	if _state != MeleeState.APPROACH:
		_clear_goal()

	_append_transition_log(distance_to_target)


func _run_approach(delta: float) -> String:
	var refresh_reason := ""
	if _should_refresh_goal():
		refresh_reason = _refresh_approach_goal()

	if not _has_selected_goal:
		velocity.x = 0.0
		velocity.z = 0.0
		_last_motion_reason = "no_goal:%s" % _last_goal_failure_reason
		return "approach no_goal"

	_nav_agent.target_position = _selected_goal_position
	var next_position := _get_meaningful_next_path_position()
	var horizontal_offset := next_position - global_position
	horizontal_offset.y = 0.0

	if horizontal_offset.length_squared() <= 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		_last_motion_reason = "goal_reached_or_same_point"
		return "approach settle"

	var move_direction := horizontal_offset.normalized()
	if _recovery_elapsed > 0.0:
		var tangent := Vector3(-move_direction.z, 0.0, move_direction.x) * _recovery_sign
		move_direction = (move_direction * 0.35 + tangent).normalized()
		_recovery_elapsed = maxf(_recovery_elapsed - delta, 0.0)
		refresh_reason = "stuck_lateral"

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	_last_motion_reason = "moving_to_goal"

	if refresh_reason.is_empty():
		return "approach"
	return "approach %s" % refresh_reason


func _run_close_adjust(delta: float, distance_to_target: float) -> String:
	var target_position := _get_target_floor_position()
	var from_target := global_position - target_position
	from_target.y = 0.0

	if from_target.length_squared() <= 0.0001:
		from_target = -basis.z
		from_target.y = 0.0

	var desired_point := target_position + from_target.normalized() * desired_stop_distance
	var adjust_offset := desired_point - global_position
	adjust_offset.y = 0.0

	var state_text := "close_adjust"
	if _recovery_elapsed > 0.0:
		var radial := from_target.normalized()
		var tangent := Vector3(-radial.z, 0.0, radial.x) * _recovery_sign
		adjust_offset = tangent * desired_stop_distance * 0.6
		_recovery_elapsed = maxf(_recovery_elapsed - delta, 0.0)
		state_text = "close_adjust lateral"

	if distance_to_target <= desired_stop_distance and adjust_offset.length_squared() <= 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		_last_motion_reason = "close_adjust_in_hold_window"
		return state_text

	if adjust_offset.length_squared() <= 0.0025:
		velocity.x = 0.0
		velocity.z = 0.0
		_last_motion_reason = "close_adjust_tiny_offset"
		return state_text

	var move_direction := adjust_offset.normalized()
	var close_speed := move_speed * close_adjust_speed_scale
	velocity.x = move_direction.x * close_speed
	velocity.z = move_direction.z * close_speed
	_last_motion_reason = "close_adjust_move"
	return state_text


func _run_melee_hold() -> String:
	velocity.x = 0.0
	velocity.z = 0.0
	_last_motion_reason = "melee_hold_zero_velocity"
	return "melee_hold"


func _should_refresh_goal() -> bool:
	if _target_node == null:
		return false
	if not _has_selected_goal:
		return true
	if _goal_refresh_elapsed < goal_refresh_min_interval:
		return false
	if _goal_age >= goal_commit_time:
		return true

	var target_anchor := _get_target_floor_position()
	return target_anchor.distance_to(_last_target_anchor) >= target_move_replan_distance


func _refresh_approach_goal() -> String:
	if _target_node == null:
		_last_goal_failure_reason = "no_target"
		return "no_target"

	var target_anchor := _get_target_floor_position()
	var chosen_goal: Variant = _select_best_melee_goal(target_anchor)
	if chosen_goal == null:
		_clear_goal()
		if _last_goal_failure_reason == "none":
			_last_goal_failure_reason = "no_valid_candidate"
		return "goal_invalid"

	_selected_goal_position = chosen_goal
	_has_selected_goal = true
	_goal_age = 0.0
	_goal_refresh_elapsed = 0.0
	_last_target_anchor = target_anchor
	_last_goal_reason = "approach_goal"
	_last_goal_failure_reason = "none"
	_goal_change_count += 1
	return "goal_refresh"


func _select_best_melee_goal(target_anchor: Vector3) -> Variant:
	var to_enemy := global_position - target_anchor
	to_enemy.y = 0.0
	var base_angle := atan2(to_enemy.z, to_enemy.x)
	var best_goal: Variant = null
	var best_score := INF
	var candidate_count: int = max(melee_ring_candidates, 1)
	var rejected_projection_count := 0
	var rejected_path_count := 0
	var rejected_invalid_map_count := 0

	for candidate_index in candidate_count:
		var angle := base_angle + (TAU * float(candidate_index) / float(candidate_count))
		var candidate := target_anchor + Vector3(cos(angle), 0.0, sin(angle)) * desired_stop_distance
		var score := _score_goal_candidate(candidate)
		match _last_goal_failure_reason:
			"invalid_navigation_map":
				rejected_invalid_map_count += 1
			"start_projection_failed", "candidate_projection_failed":
				rejected_projection_count += 1
			"path_empty":
				rejected_path_count += 1
		if score < best_score:
			best_score = score
			best_goal = _project_position_to_nav(candidate)

	if best_goal == null:
		if rejected_invalid_map_count == candidate_count:
			_last_goal_failure_reason = "invalid_navigation_map"
		elif rejected_projection_count > 0:
			_last_goal_failure_reason = "projection_failed start_or_candidate"
		elif rejected_path_count > 0:
			_last_goal_failure_reason = "path_empty_all_candidates"
		else:
			_last_goal_failure_reason = "no_valid_candidate"

	return best_goal


func _score_goal_candidate(candidate: Vector3) -> float:
	var navigation_map := _nav_agent.get_navigation_map()
	if navigation_map.is_valid() == false:
		_last_goal_failure_reason = "invalid_navigation_map"
		return INF

	var start_on_nav: Variant = _project_position_to_nav(global_position)
	if start_on_nav == null:
		_last_goal_failure_reason = "start_projection_failed"
		return INF

	var candidate_on_nav: Variant = _project_position_to_nav(candidate)
	if candidate_on_nav == null:
		_last_goal_failure_reason = "candidate_projection_failed"
		return INF

	var path := NavigationServer3D.map_get_path(
		navigation_map,
		start_on_nav,
		candidate_on_nav,
		true,
		_nav_agent.navigation_layers
	)
	if path.size() == 0:
		_last_goal_failure_reason = "path_empty"
		return INF

	var total_length := 0.0
	var previous := global_position
	for path_point in path:
		total_length += previous.distance_to(path_point)
		previous = path_point

	return total_length


func _get_meaningful_next_path_position() -> Vector3:
	var raw_next_position := _nav_agent.get_next_path_position()
	var raw_horizontal_offset := raw_next_position - global_position
	raw_horizontal_offset.y = 0.0
	if raw_horizontal_offset.length() > nav_waypoint_min_offset:
		return raw_next_position

	var path: PackedVector3Array = _nav_agent.get_current_navigation_path()
	for path_point in path:
		var horizontal_offset := path_point - global_position
		horizontal_offset.y = 0.0
		if horizontal_offset.length() > nav_waypoint_min_offset:
			return path_point

	return _selected_goal_position


func _project_position_to_nav(world_position: Vector3) -> Variant:
	var navigation_map := _nav_agent.get_navigation_map()
	if navigation_map.is_valid() == false:
		return null

	var projected_position := NavigationServer3D.map_get_closest_point(navigation_map, world_position)
	if projected_position.distance_to(world_position) > nav_projection_tolerance:
		return null

	return projected_position


func _clear_goal() -> void:
	_has_selected_goal = false
	_selected_goal_position = Vector3.ZERO
	_goal_age = 0.0
	_goal_refresh_elapsed = 0.0


func _face_target(delta: float) -> void:
	if _target_node == null:
		return

	var to_target := _target_node.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.0001:
		return

	var target_yaw := atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)


func _get_target_floor_position() -> Vector3:
	if _target_node == null:
		return global_position

	var target_position := _target_node.global_position
	target_position.y = global_position.y
	return target_position


func _get_horizontal_distance_to_target() -> float:
	if _target_node == null:
		return INF

	var to_target := _target_node.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _update_stuck_state(delta: float, pre_move_position: Vector3, attempted_horizontal_move: bool) -> void:
	if not attempted_horizontal_move:
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
		_recovery_elapsed = stuck_recovery_duration
		_recovery_sign *= -1.0
		if _state == MeleeState.APPROACH:
			_goal_refresh_elapsed = goal_refresh_min_interval


func _update_debug(state_text: String, next_position: Vector3, iteration_id: int) -> void:
	var distance_to_target := -1.0
	var distance_to_next := global_position.distance_to(next_position)
	if _target_node != null:
		distance_to_target = _get_horizontal_distance_to_target()

	_refresh_label(state_text, next_position, iteration_id, distance_to_target, distance_to_next)
	_update_nav_path_debug()

	if not debug_enabled:
		return

	_maybe_append_debug_log(state_text, next_position, iteration_id, distance_to_target, distance_to_next)


func _refresh_label(
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

	var lines: Array[String] = []
	if show_hp_label:
		lines.append("HP: %.0f/%.0f" % [_current_hp, max_hp])

	if debug_enabled:
		lines.append_array([
			"state: %s" % _get_state_name(_state),
			"move: %s" % state_text,
			"motion_reason: %s" % _last_motion_reason,
			"iter: %d" % iteration_id,
			"stuck: %.2f" % _stuck_elapsed,
			"d_target: %.2f" % distance_to_target,
			"d_goal: %.2f" % distance_to_next,
			"goal_age: %.2f" % _goal_age,
			"goal_reason: %s" % _last_goal_reason,
			"goal_fail: %s" % _last_goal_failure_reason,
			"state_changes: %d" % _state_change_count,
			"goal_changes: %d" % _goal_change_count,
			"goal: %.2f, %.2f" % [next_position.x, next_position.z],
		])

	_debug_label.text = "\n".join(lines)


func _get_state_name(state: MeleeState) -> String:
	match state:
		MeleeState.APPROACH:
			return "approach"
		MeleeState.CLOSE_ADJUST:
			return "close_adjust"
		MeleeState.MELEE_HOLD:
			return "melee_hold"
	return "unknown"


func _append_transition_log(distance_to_target: float) -> void:
	_last_goal_reason = "state:%s d=%.2f" % [_get_state_name(_state), distance_to_target]


func _update_nav_path_debug() -> void:
	if _nav_path_debug == null or _nav_path_mesh == null:
		return

	if not _is_enemy_nav_path_enabled():
		_clear_nav_path_debug()
		return

	var path: PackedVector3Array = _nav_agent.get_current_navigation_path()
	if path.size() == 0:
		_clear_nav_path_debug()
		return

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 0.85, 0.2, 1.0)
	material.vertex_color_use_as_albedo = true

	_nav_path_mesh.clear_surfaces()
	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	_nav_path_mesh.surface_set_color(material.albedo_color)
	_nav_path_mesh.surface_add_vertex(Vector3.UP * 0.15)
	var path_count: int = path.size()
	for path_index in path_count:
		var path_point: Vector3 = path[path_index]
		_nav_path_mesh.surface_add_vertex(to_local(path_point + Vector3.UP * 0.15))
	_nav_path_mesh.surface_end()
	_nav_path_debug.visible = true


func _clear_nav_path_debug() -> void:
	if _nav_path_mesh != null:
		_nav_path_mesh.clear_surfaces()

	if _nav_path_debug != null:
		_nav_path_debug.visible = false


func _get_debug_overlay() -> Node:
	return get_tree().get_first_node_in_group("debug_overlay")


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
	if not debug_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- enemy debug session start ---")
	file.flush()

	var movement_file := FileAccess.open(MOVEMENT_DEBUG_LOG_PATH, FileAccess.WRITE)
	if movement_file == null:
		return

	movement_file.store_line("--- enemy movement debug session start ---")
	movement_file.flush()


func _maybe_append_debug_log(
	state_text: String,
	next_position: Vector3,
	iteration_id: int,
	distance_to_target: float,
	distance_to_next: float
) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_debug_write_msec < DEBUG_WRITE_INTERVAL_MSEC:
		return

	_last_debug_write_msec = now_msec

	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line(
		"%s | enemy=%s | state=%s | move=%s | pos=(%.2f, %.2f, %.2f) | iter=%d | d_target=%.2f | d_goal=%.2f | goal_age=%.2f | goal_reason=%s | goal=(%.2f, %.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			_get_state_name(_state),
			state_text,
			global_position.x,
			global_position.y,
			global_position.z,
			iteration_id,
			distance_to_target,
			distance_to_next,
			_goal_age,
			_last_goal_reason,
			next_position.x,
			next_position.y,
			next_position.z,
		]
	)
	file.flush()

	_append_movement_debug_log(state_text, next_position, iteration_id, distance_to_target, distance_to_next)


func _append_movement_debug_log(
	state_text: String,
	next_position: Vector3,
	iteration_id: int,
	distance_to_target: float,
	distance_to_next: float
) -> void:
	var movement_file := FileAccess.open(MOVEMENT_DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if movement_file == null:
		return

	movement_file.seek_end()
	movement_file.store_line(
		"%s | enemy=%s | state=%s | move=%s | motion_reason=%s | goal_reason=%s | goal_fail=%s | pos=(%.2f, %.2f, %.2f) | vel=(%.2f, %.2f, %.2f) | iter=%d | d_target=%.2f | d_goal=%.2f | goal=(%.2f, %.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			_get_state_name(_state),
			state_text,
			_last_motion_reason,
			_last_goal_reason,
			_last_goal_failure_reason,
			global_position.x,
			global_position.y,
			global_position.z,
			velocity.x,
			velocity.y,
			velocity.z,
			iteration_id,
			distance_to_target,
			distance_to_next,
			next_position.x,
			next_position.y,
			next_position.z,
		]
	)
	movement_file.flush()


func apply_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	if _current_hp <= 0.0:
		queue_free()


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	_refresh_label("idle", Vector3.ZERO, 0)


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)
