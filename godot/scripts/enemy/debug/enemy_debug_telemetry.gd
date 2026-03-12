extends RefCounted

const EnemyDebugSnapshot = preload("res://scripts/enemy/debug/enemy_debug_snapshot.gd")

static var _profiling_enabled: bool = false
static var _profile_window_start_usec: int = 0
static var _profile_physics_total_usec: int = 0
static var _profile_goal_total_usec: int = 0
static var _profile_yield_total_usec: int = 0
static var _profile_label_total_usec: int = 0
static var _profile_nav_debug_total_usec: int = 0
static var _profile_nav_query_total_usec: int = 0
static var _profile_move_slide_total_usec: int = 0
static var _profile_state_dispatch_total_usec: int = 0
static var _profile_close_adjust_total_usec: int = 0
static var _profile_snapshot_total_usec: int = 0
static var _profile_influence_total_usec: int = 0
static var _profile_prepare_total_usec: int = 0
static var _profile_horizontal_phase_total_usec: int = 0
static var _profile_melee_state_total_usec: int = 0
static var _profile_state_motion_total_usec: int = 0
static var _profile_finalize_total_usec: int = 0
static var _profile_stuck_total_usec: int = 0
static var _profile_hold_debug_total_usec: int = 0
static var _profile_update_debug_total_usec: int = 0
static var _profile_local_enemy_total_usec: int = 0
static var _profile_physics_calls: int = 0
static var _profile_goal_calls: int = 0
static var _profile_yield_calls: int = 0
static var _pending_melee_hold_log_lines: Array[String] = []
static var _last_melee_hold_flush_msec: int = 0

const DEBUG_LOG_PATH := "user://debug/enemy_debug.log"
const GOAL_PROJECTION_DEBUG_PATH := "user://debug/enemy_goal_projection_debug.txt"
const MELEE_HOLD_DEBUG_PATH := "user://debug/enemy_melee_hold_debug.txt"
const DEBUG_WRITE_INTERVAL_MSEC := 500
const MELEE_HOLD_DEBUG_INTERVAL_MSEC := 100
const MELEE_HOLD_DEBUG_FLUSH_INTERVAL_MSEC := 500
const MELEE_HOLD_DEBUG_FLUSH_LINE_COUNT := 32
const DEBUG_LABEL_REFRESH_INTERVAL_SEC := 0.12
const NAV_DEBUG_REFRESH_INTERVAL_SEC := 0.12


class GoalPathDebugInfo:
	extends RefCounted

	var path_end: Vector3 = Vector3.ZERO
	var path_end_error: float = 0.0


var _owner: Node3D
var _debug_label: Label3D
var _nav_path_debug: MeshInstance3D
var _nav_path_mesh: ImmediateMesh
var _path_debug_material: StandardMaterial3D
var _goal_debug_material: StandardMaterial3D
var _candidate_debug_material: StandardMaterial3D
var _debug_overlay_cache: Node
var _last_debug_write_msec: int = 0
var _last_melee_hold_log_msec: int = 0
var _last_melee_hold_log_signature: String = ""
var _debug_label_refresh_remaining: float = 0.0
var _nav_debug_refresh_remaining: float = 0.0


func setup(owner: Node3D, debug_label: Label3D, nav_path_debug: MeshInstance3D) -> void:
	_owner = owner
	_debug_label = debug_label
	if _debug_label != null:
		_debug_label.visible = false
	_nav_path_debug = nav_path_debug
	_nav_path_mesh = ImmediateMesh.new()
	_nav_path_debug.mesh = _nav_path_mesh
	_path_debug_material = _build_debug_material(Color(0.95, 0.85, 0.2, 1.0))
	_goal_debug_material = _build_debug_material(Color(0.2, 0.9, 0.45, 1.0))
	_candidate_debug_material = _build_debug_material(Color(0.35, 0.7, 1.0, 0.8))


func tick(delta: float) -> void:
	if _debug_label_refresh_remaining > 0.0:
		_debug_label_refresh_remaining = maxf(_debug_label_refresh_remaining - delta, 0.0)
	if _nav_debug_refresh_remaining > 0.0:
		_nav_debug_refresh_remaining = maxf(_nav_debug_refresh_remaining - delta, 0.0)
	_flush_pending_melee_hold_debug_log_if_needed()


func needs_debug_snapshot(
	debug_enabled: bool,
	show_hp_label: bool,
	debug_log_enabled: bool,
	melee_hold_debug_enabled: bool
) -> bool:
	var needs_nav_debug: bool = is_enemy_nav_path_enabled()
	var needs_debug_log: bool = debug_enabled and debug_log_enabled
	return needs_nav_debug or needs_debug_log or melee_hold_debug_enabled


func prepare_debug_log(debug_enabled: bool, debug_log_enabled: bool) -> void:
	if not debug_enabled or not debug_log_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- enemy debug session start ---")
	file.flush()

	var goal_projection_file := FileAccess.open(GOAL_PROJECTION_DEBUG_PATH, FileAccess.WRITE)
	if goal_projection_file == null:
		return

	goal_projection_file.store_line("--- enemy goal projection debug session start ---")
	goal_projection_file.flush()


func prepare_melee_hold_debug_log(melee_hold_debug_enabled: bool) -> void:
	if not melee_hold_debug_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(MELEE_HOLD_DEBUG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- melee hold debug session start ---")
	file.flush()
	_last_melee_hold_log_msec = Time.get_ticks_msec()
	_last_melee_hold_log_signature = ""
	_last_melee_hold_flush_msec = _last_melee_hold_log_msec
	_pending_melee_hold_log_lines.clear()


func refresh_label_if_needed(snapshot: EnemyDebugSnapshot, state_text: String, next_position: Vector3, iteration_id: int) -> void:
	if _debug_label == null:
		return
	_debug_label.visible = false


func refresh_label(snapshot: EnemyDebugSnapshot, state_text: String, next_position: Vector3, iteration_id: int) -> void:
	var profile_start_usec := profile_start_usec()
	if _debug_label == null:
		record_profile_duration("label", Time.get_ticks_usec() - profile_start_usec)
		return

	_debug_label.visible = false
	record_profile_duration("label", Time.get_ticks_usec() - profile_start_usec)


func update_debug(snapshot: EnemyDebugSnapshot, state_text: String, next_position: Vector3, iteration_id: int) -> void:
	refresh_label_if_needed(snapshot, state_text, next_position, iteration_id)
	update_nav_path_debug_if_needed(snapshot)
	if not snapshot.debug_enabled:
		return
	append_debug_log(snapshot, state_text, next_position, iteration_id)


func update_nav_path_debug_if_needed(snapshot: EnemyDebugSnapshot) -> void:
	if _nav_path_debug == null or _nav_path_mesh == null:
		return
	if not is_enemy_nav_path_enabled():
		clear_nav_path_debug()
		return
	if _nav_debug_refresh_remaining > 0.0:
		return

	_nav_debug_refresh_remaining = NAV_DEBUG_REFRESH_INTERVAL_SEC
	update_nav_path_debug(snapshot)


func update_nav_path_debug(snapshot: EnemyDebugSnapshot) -> void:
	var profile_start_usec := profile_start_usec()
	_nav_path_mesh.clear_surfaces()
	draw_current_path(snapshot.current_path)
	draw_goal_marker(snapshot.has_goal, snapshot.current_goal_position)
	draw_candidate_ring(snapshot.debug_candidate_positions)
	_nav_path_debug.visible = _nav_path_mesh.get_surface_count() > 0
	record_profile_duration("nav_debug", Time.get_ticks_usec() - profile_start_usec)


func capture_goal_path_debug(current_path: PackedVector3Array, current_goal_position: Vector3) -> GoalPathDebugInfo:
	var result: GoalPathDebugInfo = GoalPathDebugInfo.new()
	if current_path.is_empty():
		return result

	var path_end: Vector3 = current_path[current_path.size() - 1]
	result.path_end = path_end
	result.path_end_error = _horizontal_distance(path_end, current_goal_position)
	return result


func can_append_melee_hold_debug_log(melee_hold_debug_enabled: bool) -> bool:
	if not melee_hold_debug_enabled:
		return false
	var now_msec := Time.get_ticks_msec()
	return now_msec - _last_melee_hold_log_msec >= MELEE_HOLD_DEBUG_INTERVAL_MSEC


func append_melee_hold_debug_log(snapshot: EnemyDebugSnapshot, state_text: String, next_position: Vector3) -> void:
	if not snapshot.melee_hold_debug_enabled:
		return
	var should_log: bool = snapshot.debug_hold_displacement >= snapshot.melee_hold_displacement_log_threshold
	should_log = should_log or snapshot.debug_hold_collision_count > 0
	should_log = should_log or snapshot.debug_hold_has_yield
	if not should_log:
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_melee_hold_log_msec < MELEE_HOLD_DEBUG_INTERVAL_MSEC:
		return
	_last_melee_hold_log_msec = now_msec
	var collision_names: Array[String] = snapshot.debug_hold_collision_names
	var current_goal_position: Vector3 = snapshot.current_goal_position
	var log_signature: String = "enemy=%s | state=%s | pos=(%.2f, %.2f, %.2f) | d_target=%.3f | hold_margin=%.3f | disp=%.4f | vel=%.3f | yield=%s | yield_speed=%.3f | yield_direct=%.3f | yield_chain=%.3f | collisions=%d | colliders=%s | next=(%.2f, %.2f, %.2f) | nav_refresh=%s | path_pts=%d | goal=%s | goal_at=(%.2f, %.2f, %.2f)" % [
		snapshot.enemy_name,
		state_text,
		snapshot.global_position.x,
		snapshot.global_position.y,
		snapshot.global_position.z,
		snapshot.distance_to_target,
		snapshot.hold_margin,
		snapshot.debug_hold_displacement,
		snapshot.debug_hold_velocity,
		str(snapshot.debug_hold_has_yield),
		snapshot.debug_yield_speed,
		snapshot.debug_yield_direct_pressure,
		snapshot.debug_yield_chain_pressure,
		snapshot.debug_hold_collision_count,
		",".join(collision_names),
		next_position.x,
		next_position.y,
		next_position.z,
		str(snapshot.debug_nav_cache_refreshed),
		snapshot.path_point_count,
		str(snapshot.has_goal),
		current_goal_position.x,
		current_goal_position.y,
		current_goal_position.z,
	]
	if log_signature == _last_melee_hold_log_signature:
		return

	_last_melee_hold_log_signature = log_signature
	_pending_melee_hold_log_lines.append(
		"%s | %s" % [
			Time.get_datetime_string_from_system(),
			log_signature,
		]
	)
	_flush_pending_melee_hold_debug_log_if_needed()


func append_debug_log(snapshot: EnemyDebugSnapshot, state_text: String, next_position: Vector3, iteration_id: int) -> void:
	if not snapshot.debug_log_enabled:
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_debug_write_msec < DEBUG_WRITE_INTERVAL_MSEC:
		return
	_last_debug_write_msec = now_msec
	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return
	var current_goal_position: Vector3 = snapshot.current_goal_position
	var goal_raw_candidate: Vector3 = snapshot.debug_goal_raw_candidate
	var goal_projected_candidate: Vector3 = snapshot.debug_goal_projected_candidate
	var goal_path_end: Vector3 = snapshot.debug_goal_path_end
	var yield_direction: Vector3 = snapshot.debug_yield_direction
	var goal_vertical_delta: float = absf(goal_projected_candidate.y - goal_raw_candidate.y)
	var goal_selected_path_length: float = snapshot.debug_goal_selected_path_length
	var goal_path_empty: bool = is_inf(goal_selected_path_length)
	file.seek_end()
	file.store_line(
		"%s | enemy=%s | pos=(%.2f, %.2f, %.2f) | close_state=%s | close_state_age=%.2f | close_state_changes=%d | state=%s | iter=%d | goal=%s | goal_at=(%.2f, %.2f, %.2f) | path_pts=%d | goal_candidates=%d | goal_reject_proj=%d | goal_reject_failed=%d | goal_unreachable_shortlist=%d | goal_fallback=%s | goal_raw=(%.2f, %.2f, %.2f) | goal_proj=(%.2f, %.2f, %.2f) | goal_proj_err=%.2f | goal_vert_err=%.2f | goal_path_len=%s | goal_path_empty=%s | path_end=(%.2f, %.2f, %.2f) | path_end_err=%.2f | d_target=%.2f | d_next=%.2f | next=(%.2f, %.2f, %.2f) | nav_refresh=%s | cadj_path_dist=%.2f | cadj_gap=%.2f | cadj_crowd=%.2f | cadj_left=%.2f | cadj_right=%.2f | cadj_side=%.0f | cadj_lat=%.2f | cadj_speed=%.2f | yield_speed=%.2f | yield_strength=%.2f | yield_neighbors=%d | yield_penalty=%.2f | crowd_pressure=%.2f | yield_direct=%.2f | yield_chain=%.2f | yield_dir=(%.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			snapshot.enemy_name,
			snapshot.global_position.x,
			snapshot.global_position.y,
			snapshot.global_position.z,
			snapshot.melee_state_name,
			snapshot.melee_state_age,
			snapshot.melee_state_transition_count,
			state_text,
			iteration_id,
			str(snapshot.has_goal),
			current_goal_position.x,
			current_goal_position.y,
			current_goal_position.z,
			snapshot.path_point_count,
			snapshot.debug_goal_candidate_count,
			snapshot.debug_goal_rejected_projection_count,
			snapshot.debug_goal_rejected_failed_count,
			snapshot.debug_goal_unreachable_path_count,
			str(snapshot.debug_goal_used_fallback),
			goal_raw_candidate.x,
			goal_raw_candidate.y,
			goal_raw_candidate.z,
			goal_projected_candidate.x,
			goal_projected_candidate.y,
			goal_projected_candidate.z,
			snapshot.debug_goal_projection_error,
			goal_vertical_delta,
			"INF" if goal_path_empty else "%.2f" % goal_selected_path_length,
			str(goal_path_empty),
			goal_path_end.x,
			goal_path_end.y,
			goal_path_end.z,
			snapshot.debug_goal_path_end_error,
			snapshot.distance_to_target,
			snapshot.distance_to_next,
			next_position.x,
			next_position.y,
			next_position.z,
			str(snapshot.debug_nav_cache_refreshed),
			snapshot.debug_close_adjust_path_distance,
			snapshot.debug_close_adjust_target_gap,
			snapshot.debug_close_adjust_crowd_pressure,
			snapshot.debug_close_adjust_left_penalty,
			snapshot.debug_close_adjust_right_penalty,
			snapshot.debug_close_adjust_side_sign,
			snapshot.debug_close_adjust_lateral_weight,
			snapshot.debug_close_adjust_move_speed,
			snapshot.debug_yield_speed,
			snapshot.debug_yield_strength,
			snapshot.debug_yield_neighbor_count,
			snapshot.debug_yield_penalty,
			snapshot.debug_crowd_pressure,
			snapshot.debug_yield_direct_pressure,
			snapshot.debug_yield_chain_pressure,
			yield_direction.x,
			yield_direction.z,
		]
	)
	file.flush()

	var goal_projection_file := FileAccess.open(GOAL_PROJECTION_DEBUG_PATH, FileAccess.READ_WRITE)
	if goal_projection_file == null:
		return

	goal_projection_file.seek_end()
	goal_projection_file.store_line(
		"%s | enemy=%s | state=%s | pos=(%.2f, %.2f, %.2f) | goal=%s | fallback=%s | raw=(%.2f, %.2f, %.2f) | proj=(%.2f, %.2f, %.2f) | horiz_err=%.2f | vert_err=%.2f | selected_path_len=%s | path_empty=%s | unreachable_shortlist=%d | path_end_err=%.2f" % [
			Time.get_datetime_string_from_system(),
			snapshot.enemy_name,
			state_text,
			snapshot.global_position.x,
			snapshot.global_position.y,
			snapshot.global_position.z,
			str(snapshot.has_goal),
			str(snapshot.debug_goal_used_fallback),
			goal_raw_candidate.x,
			goal_raw_candidate.y,
			goal_raw_candidate.z,
			goal_projected_candidate.x,
			goal_projected_candidate.y,
			goal_projected_candidate.z,
			snapshot.debug_goal_projection_error,
			goal_vertical_delta,
			"INF" if goal_path_empty else "%.2f" % goal_selected_path_length,
			str(goal_path_empty),
			snapshot.debug_goal_unreachable_path_count,
			snapshot.debug_goal_path_end_error,
		]
	)
	goal_projection_file.flush()


func clear_nav_path_debug() -> void:
	if _nav_path_mesh != null:
		_nav_path_mesh.clear_surfaces()
	if _nav_path_debug != null:
		_nav_path_debug.visible = false


func is_enemy_status_enabled() -> bool:
	var debug_overlay := _get_debug_overlay()
	if debug_overlay != null and debug_overlay.has_method("is_enemy_status_enabled"):
		return debug_overlay.is_enemy_status_enabled()
	return true


func is_enemy_nav_path_enabled() -> bool:
	var debug_overlay := _get_debug_overlay()
	if debug_overlay != null and debug_overlay.has_method("is_enemy_nav_path_enabled"):
		return debug_overlay.is_enemy_nav_path_enabled()
	return false


static func set_profiling_enabled(enabled: bool) -> void:
	_profiling_enabled = enabled
	_reset_profile_accumulators()


static func get_profile_snapshot(enemy_count: int) -> Dictionary:
	if _profile_window_start_usec <= 0:
		return {}

	var now_usec: int = Time.get_ticks_usec()
	var window_usec: int = maxi(now_usec - _profile_window_start_usec, 1)
	var physics_total_ms: float = float(_profile_physics_total_usec) / 1000.0
	return {
		"window_sec": float(window_usec) / 1000000.0,
		"enemy_count": enemy_count,
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
		"state_dispatch_total_ms": float(_profile_state_dispatch_total_usec) / 1000.0,
		"state_dispatch_share": _safe_profile_share(_profile_state_dispatch_total_usec, _profile_physics_total_usec),
		"close_adjust_total_ms": float(_profile_close_adjust_total_usec) / 1000.0,
		"close_adjust_share": _safe_profile_share(_profile_close_adjust_total_usec, _profile_physics_total_usec),
		"snapshot_total_ms": float(_profile_snapshot_total_usec) / 1000.0,
		"snapshot_share": _safe_profile_share(_profile_snapshot_total_usec, _profile_physics_total_usec),
		"influence_total_ms": float(_profile_influence_total_usec) / 1000.0,
		"influence_share": _safe_profile_share(_profile_influence_total_usec, _profile_physics_total_usec),
		"prepare_total_ms": float(_profile_prepare_total_usec) / 1000.0,
		"prepare_share": _safe_profile_share(_profile_prepare_total_usec, _profile_physics_total_usec),
		"horizontal_phase_total_ms": float(_profile_horizontal_phase_total_usec) / 1000.0,
		"horizontal_phase_share": _safe_profile_share(_profile_horizontal_phase_total_usec, _profile_physics_total_usec),
		"melee_state_total_ms": float(_profile_melee_state_total_usec) / 1000.0,
		"melee_state_share": _safe_profile_share(_profile_melee_state_total_usec, _profile_physics_total_usec),
		"state_motion_total_ms": float(_profile_state_motion_total_usec) / 1000.0,
		"state_motion_share": _safe_profile_share(_profile_state_motion_total_usec, _profile_physics_total_usec),
		"finalize_total_ms": float(_profile_finalize_total_usec) / 1000.0,
		"finalize_share": _safe_profile_share(_profile_finalize_total_usec, _profile_physics_total_usec),
		"stuck_total_ms": float(_profile_stuck_total_usec) / 1000.0,
		"stuck_share": _safe_profile_share(_profile_stuck_total_usec, _profile_physics_total_usec),
		"hold_debug_total_ms": float(_profile_hold_debug_total_usec) / 1000.0,
		"hold_debug_share": _safe_profile_share(_profile_hold_debug_total_usec, _profile_physics_total_usec),
		"update_debug_total_ms": float(_profile_update_debug_total_usec) / 1000.0,
		"update_debug_share": _safe_profile_share(_profile_update_debug_total_usec, _profile_physics_total_usec),
		"local_enemy_total_ms": float(_profile_local_enemy_total_usec) / 1000.0,
		"local_enemy_share": _safe_profile_share(_profile_local_enemy_total_usec, _profile_physics_total_usec),
	}


static func profile_start_usec() -> int:
	if not _profiling_enabled:
		return 0
	if _profile_window_start_usec <= 0:
		_profile_window_start_usec = Time.get_ticks_usec()
	return Time.get_ticks_usec()


static func record_profile_duration(section: String, duration_usec: int) -> void:
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
		"state_dispatch":
			_profile_state_dispatch_total_usec += duration_usec
		"close_adjust":
			_profile_close_adjust_total_usec += duration_usec
		"snapshot":
			_profile_snapshot_total_usec += duration_usec
		"influence":
			_profile_influence_total_usec += duration_usec
		"prepare":
			_profile_prepare_total_usec += duration_usec
		"horizontal_phase":
			_profile_horizontal_phase_total_usec += duration_usec
		"melee_state":
			_profile_melee_state_total_usec += duration_usec
		"state_motion":
			_profile_state_motion_total_usec += duration_usec
		"finalize":
			_profile_finalize_total_usec += duration_usec
		"stuck":
			_profile_stuck_total_usec += duration_usec
		"hold_debug":
			_profile_hold_debug_total_usec += duration_usec
		"update_debug":
			_profile_update_debug_total_usec += duration_usec
		"local_enemy":
			_profile_local_enemy_total_usec += duration_usec


func draw_current_path(path: PackedVector3Array) -> void:
	if path.is_empty():
		return
	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _path_debug_material)
	_nav_path_mesh.surface_set_color(_path_debug_material.albedo_color)
	_nav_path_mesh.surface_add_vertex(Vector3.UP * 0.15)
	for path_point in path:
		_nav_path_mesh.surface_add_vertex(_owner.to_local(path_point + Vector3.UP * 0.15))
	_nav_path_mesh.surface_end()


func draw_goal_marker(has_goal: bool, current_goal_position: Vector3) -> void:
	if not has_goal:
		return
	var local_goal := _owner.to_local(current_goal_position + Vector3.UP * 0.2)
	var marker_extent := 0.18
	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _goal_debug_material)
	_nav_path_mesh.surface_set_color(_goal_debug_material.albedo_color)
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(-marker_extent, 0.0, 0.0))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(marker_extent, 0.0, 0.0))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(0.0, 0.0, -marker_extent))
	_nav_path_mesh.surface_add_vertex(local_goal + Vector3(0.0, 0.0, marker_extent))
	_nav_path_mesh.surface_end()


func draw_candidate_ring(candidate_positions: PackedVector3Array) -> void:
	if candidate_positions.size() < 2:
		return
	_nav_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _candidate_debug_material)
	_nav_path_mesh.surface_set_color(_candidate_debug_material.albedo_color)
	for candidate_position in candidate_positions:
		_nav_path_mesh.surface_add_vertex(_owner.to_local(candidate_position + Vector3.UP * 0.1))
	_nav_path_mesh.surface_add_vertex(_owner.to_local(candidate_positions[0] + Vector3.UP * 0.1))
	_nav_path_mesh.surface_end()


func _get_debug_overlay() -> Node:
	if _debug_overlay_cache != null and is_instance_valid(_debug_overlay_cache):
		return _debug_overlay_cache
	_debug_overlay_cache = _owner.get_tree().get_first_node_in_group("debug_overlay")
	return _debug_overlay_cache


func _build_debug_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	return material


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
	_profile_state_dispatch_total_usec = 0
	_profile_close_adjust_total_usec = 0
	_profile_snapshot_total_usec = 0
	_profile_influence_total_usec = 0
	_profile_prepare_total_usec = 0
	_profile_horizontal_phase_total_usec = 0
	_profile_melee_state_total_usec = 0
	_profile_state_motion_total_usec = 0
	_profile_finalize_total_usec = 0
	_profile_stuck_total_usec = 0
	_profile_hold_debug_total_usec = 0
	_profile_update_debug_total_usec = 0
	_profile_local_enemy_total_usec = 0
	_profile_physics_calls = 0
	_profile_goal_calls = 0
	_profile_yield_calls = 0


func _flush_pending_melee_hold_debug_log_if_needed(force: bool = false) -> void:
	if _pending_melee_hold_log_lines.is_empty():
		return

	var now_msec: int = Time.get_ticks_msec()
	if not force:
		var should_flush_by_time: bool = now_msec - _last_melee_hold_flush_msec >= MELEE_HOLD_DEBUG_FLUSH_INTERVAL_MSEC
		var should_flush_by_size: bool = _pending_melee_hold_log_lines.size() >= MELEE_HOLD_DEBUG_FLUSH_LINE_COUNT
		if not should_flush_by_time and not should_flush_by_size:
			return

	var file := FileAccess.open(MELEE_HOLD_DEBUG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	for line in _pending_melee_hold_log_lines:
		file.store_line(line)
	file.flush()
	_pending_melee_hold_log_lines.clear()
	_last_melee_hold_flush_msec = now_msec


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()
