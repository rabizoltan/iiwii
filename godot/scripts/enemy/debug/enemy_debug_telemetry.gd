extends RefCounted

const EnemyDebugSnapshot = preload("res://scripts/enemy/debug/enemy_debug_snapshot.gd")

static var _profiling_enabled: bool = false
static var _profile_window_start_usec: int = 0
static var _profile_physics_total_usec: int = 0
static var _profile_goal_total_usec: int = 0
static var _profile_yield_total_usec: int = 0
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
static var _profile_update_debug_total_usec: int = 0
static var _profile_local_enemy_total_usec: int = 0
static var _profile_nearby_enemy_total_usec: int = 0
static var _profile_goal_path_total_usec: int = 0
static var _profile_frontline_total_usec: int = 0
static var _profile_physics_calls: int = 0
static var _profile_goal_calls: int = 0
static var _profile_yield_calls: int = 0
static var _profile_goal_refresh_checks: int = 0
static var _profile_goal_refresh_triggers: int = 0
static var _profile_goal_selection_successes: int = 0
static var _profile_goal_selection_failures: int = 0
static var _profile_goal_selection_fallbacks: int = 0
static var _profile_nav_cache_hits: int = 0
static var _profile_nav_cache_refreshes: int = 0
static var _profile_close_adjust_calls: int = 0
static var _profile_frontline_checks: int = 0
static var _profile_state_approach_frames: int = 0
static var _profile_state_queue_frames: int = 0
static var _profile_state_close_adjust_frames: int = 0
static var _profile_state_melee_hold_frames: int = 0
static var _profile_state_move_frames: int = 0
static var _profile_state_idle_frames: int = 0
static var _profile_queue_entries: int = 0
static var _profile_queue_hold_reuses: int = 0
static var _profile_frontline_rejections: int = 0
static var _profile_approach_cap_rejections: int = 0

const NAV_DEBUG_REFRESH_INTERVAL_SEC := 0.12


var _owner: Node3D
var _nav_path_debug: MeshInstance3D
var _nav_path_mesh: ImmediateMesh
var _path_debug_material: StandardMaterial3D
var _goal_debug_material: StandardMaterial3D
var _candidate_debug_material: StandardMaterial3D
var _debug_overlay_cache: Node
var _nav_debug_refresh_remaining: float = 0.0


func setup(owner: Node3D, nav_path_debug: MeshInstance3D) -> void:
	_owner = owner
	_nav_path_debug = nav_path_debug
	_nav_path_mesh = ImmediateMesh.new()
	_nav_path_debug.mesh = _nav_path_mesh
	_path_debug_material = _build_debug_material(Color(0.95, 0.85, 0.2, 1.0))
	_goal_debug_material = _build_debug_material(Color(0.2, 0.9, 0.45, 1.0))
	_candidate_debug_material = _build_debug_material(Color(0.35, 0.7, 1.0, 0.8))


func tick(delta: float) -> void:
	if _nav_debug_refresh_remaining > 0.0:
		_nav_debug_refresh_remaining = maxf(_nav_debug_refresh_remaining - delta, 0.0)


func needs_debug_snapshot() -> bool:
	return is_enemy_nav_path_enabled()


func update_debug(snapshot: EnemyDebugSnapshot) -> void:
	update_nav_path_debug_if_needed(snapshot)


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



func clear_nav_path_debug() -> void:
	if _nav_path_mesh != null:
		_nav_path_mesh.clear_surfaces()
	if _nav_path_debug != null:
		_nav_path_debug.visible = false


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
		"update_debug_total_ms": float(_profile_update_debug_total_usec) / 1000.0,
		"update_debug_share": _safe_profile_share(_profile_update_debug_total_usec, _profile_physics_total_usec),
		"local_enemy_total_ms": float(_profile_local_enemy_total_usec) / 1000.0,
		"local_enemy_share": _safe_profile_share(_profile_local_enemy_total_usec, _profile_physics_total_usec),
		"nearby_enemy_total_ms": float(_profile_nearby_enemy_total_usec) / 1000.0,
		"nearby_enemy_share": _safe_profile_share(_profile_nearby_enemy_total_usec, _profile_physics_total_usec),
		"goal_path_total_ms": float(_profile_goal_path_total_usec) / 1000.0,
		"goal_path_share": _safe_profile_share(_profile_goal_path_total_usec, _profile_physics_total_usec),
		"frontline_total_ms": float(_profile_frontline_total_usec) / 1000.0,
		"frontline_share": _safe_profile_share(_profile_frontline_total_usec, _profile_physics_total_usec),
		"goal_refresh_checks": _profile_goal_refresh_checks,
		"goal_refresh_triggers": _profile_goal_refresh_triggers,
		"goal_selection_successes": _profile_goal_selection_successes,
		"goal_selection_failures": _profile_goal_selection_failures,
		"goal_selection_fallbacks": _profile_goal_selection_fallbacks,
		"nav_cache_hits": _profile_nav_cache_hits,
		"nav_cache_refreshes": _profile_nav_cache_refreshes,
		"close_adjust_calls": _profile_close_adjust_calls,
		"frontline_checks": _profile_frontline_checks,
		"state_approach_frames": _profile_state_approach_frames,
		"state_queue_frames": _profile_state_queue_frames,
		"state_close_adjust_frames": _profile_state_close_adjust_frames,
		"state_melee_hold_frames": _profile_state_melee_hold_frames,
		"state_move_frames": _profile_state_move_frames,
		"state_idle_frames": _profile_state_idle_frames,
		"queue_entries": _profile_queue_entries,
		"queue_hold_reuses": _profile_queue_hold_reuses,
		"frontline_rejections": _profile_frontline_rejections,
		"approach_cap_rejections": _profile_approach_cap_rejections,
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
		"update_debug":
			_profile_update_debug_total_usec += duration_usec
		"local_enemy":
			_profile_local_enemy_total_usec += duration_usec
		"nearby_enemy":
			_profile_nearby_enemy_total_usec += duration_usec
		"goal_path":
			_profile_goal_path_total_usec += duration_usec
		"frontline":
			_profile_frontline_total_usec += duration_usec


static func increment_counter(counter: String, amount: int = 1) -> void:
	if not _profiling_enabled:
		return
	if _profile_window_start_usec <= 0:
		_profile_window_start_usec = Time.get_ticks_usec()

	match counter:
		"goal_refresh_checks":
			_profile_goal_refresh_checks += amount
		"goal_refresh_triggers":
			_profile_goal_refresh_triggers += amount
		"goal_selection_successes":
			_profile_goal_selection_successes += amount
		"goal_selection_failures":
			_profile_goal_selection_failures += amount
		"goal_selection_fallbacks":
			_profile_goal_selection_fallbacks += amount
		"nav_cache_hits":
			_profile_nav_cache_hits += amount
		"nav_cache_refreshes":
			_profile_nav_cache_refreshes += amount
		"close_adjust_calls":
			_profile_close_adjust_calls += amount
		"frontline_checks":
			_profile_frontline_checks += amount
		"state_approach_frames":
			_profile_state_approach_frames += amount
		"state_queue_frames":
			_profile_state_queue_frames += amount
		"state_close_adjust_frames":
			_profile_state_close_adjust_frames += amount
		"state_melee_hold_frames":
			_profile_state_melee_hold_frames += amount
		"state_move_frames":
			_profile_state_move_frames += amount
		"state_idle_frames":
			_profile_state_idle_frames += amount
		"queue_entries":
			_profile_queue_entries += amount
		"queue_hold_reuses":
			_profile_queue_hold_reuses += amount
		"frontline_rejections":
			_profile_frontline_rejections += amount
		"approach_cap_rejections":
			_profile_approach_cap_rejections += amount


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
	_profile_update_debug_total_usec = 0
	_profile_local_enemy_total_usec = 0
	_profile_nearby_enemy_total_usec = 0
	_profile_goal_path_total_usec = 0
	_profile_frontline_total_usec = 0
	_profile_physics_calls = 0
	_profile_goal_calls = 0
	_profile_yield_calls = 0
	_profile_goal_refresh_checks = 0
	_profile_goal_refresh_triggers = 0
	_profile_goal_selection_successes = 0
	_profile_goal_selection_failures = 0
	_profile_goal_selection_fallbacks = 0
	_profile_nav_cache_hits = 0
	_profile_nav_cache_refreshes = 0
	_profile_close_adjust_calls = 0
	_profile_frontline_checks = 0
	_profile_state_approach_frames = 0
	_profile_state_queue_frames = 0
	_profile_state_close_adjust_frames = 0
	_profile_state_melee_hold_frames = 0
	_profile_state_move_frames = 0
	_profile_state_idle_frames = 0
	_profile_queue_entries = 0
	_profile_queue_hold_reuses = 0
	_profile_frontline_rejections = 0
	_profile_approach_cap_rejections = 0

