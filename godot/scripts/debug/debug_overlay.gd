extends CanvasLayer

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")
const EnemyNavPerfMonitor = preload("res://scripts/debug/enemy_nav_perf_monitor.gd")
const ENEMY_NAV_LOG_PATH := "user://enemy_nav_perf_log.csv"

@onready var _panel: PanelContainer = $PanelContainer
@onready var _projectile_line_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/ProjectileLineToggle
@onready var _enemy_nav_log_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyNavLogToggle
@onready var _perf_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PerfStats

var _menu_open: bool = false
var _projectile_debug_lines_enabled: bool = false
var _enemy_nav_log_enabled: bool = false
var _perf_refresh_remaining: float = 0.0
var _previous_enemy_nav_snapshot: Dictionary = {}
var _enemy_nav_rates_ready: bool = false
var _enemy_nav_log_start_msec: int = 0

const PERF_REFRESH_INTERVAL_SEC := 0.25


func _ready() -> void:
	add_to_group("debug_overlay")
	_projectile_line_toggle.toggled.connect(_on_projectile_line_toggled)
	_enemy_nav_log_toggle.toggled.connect(_on_enemy_nav_log_toggled)
	_sync_menu_state()


func toggle_menu() -> void:
	_menu_open = not _menu_open
	if _menu_open:
		_previous_enemy_nav_snapshot = EnemyNavPerfMonitor.get_snapshot()
		_enemy_nav_rates_ready = false
		_refresh_perf_stats()
	_sync_menu_state()


func is_projectile_debug_lines_enabled() -> bool:
	return _projectile_debug_lines_enabled


func spawn_projectile_debug_line(start_position: Vector3, end_position: Vector3, is_hit: bool) -> void:
	if not _projectile_debug_lines_enabled:
		return

	var debug_world: Node = get_parent().get_node_or_null("DebugWorld")
	if debug_world == null:
		return

	var line: Node = DEBUG_LINE_SCENE.instantiate()
	if line == null:
		return

	debug_world.add_child(line)
	if line.has_method("setup"):
		var line_color: Color = Color(0.95, 0.2, 0.2, 1.0) if is_hit else Color(0.2, 0.55, 1.0, 1.0)
		line.setup(start_position, end_position, line_color, 1.5)


func _process(delta: float) -> void:
	if not _menu_open:
		return

	_perf_refresh_remaining = maxf(_perf_refresh_remaining - delta, 0.0)
	if _perf_refresh_remaining > 0.0:
		return

	_refresh_perf_stats()


func _sync_menu_state() -> void:
	_panel.visible = _menu_open
	_projectile_line_toggle.button_pressed = _projectile_debug_lines_enabled
	_enemy_nav_log_toggle.button_pressed = _enemy_nav_log_enabled


func _on_projectile_line_toggled(enabled: bool) -> void:
	_projectile_debug_lines_enabled = enabled


func _on_enemy_nav_log_toggled(enabled: bool) -> void:
	_enemy_nav_log_enabled = enabled
	if not _enemy_nav_log_enabled:
		return

	if _enemy_nav_log_start_msec <= 0:
		_enemy_nav_log_start_msec = Time.get_ticks_msec()

	_ensure_enemy_nav_log_header()


func _refresh_perf_stats() -> void:
	_perf_refresh_remaining = PERF_REFRESH_INTERVAL_SEC
	if _perf_stats_label == null:
		return

	var fps: int = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(float(fps), 1.0)
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var projectile_count := _get_child_count_or_zero("Projectiles")
	var debug_line_count := _get_child_count_or_zero("DebugWorld")
	var enemy_nav_snapshot := EnemyNavPerfMonitor.get_snapshot()
	var nav_resolve_rate := _compute_snapshot_rate(enemy_nav_snapshot, "nav_resolve_count")
	var nav_step_rate := _compute_snapshot_rate(enemy_nav_snapshot, "nav_get_next_path_position_count")
	var nav_path_scan_rate := _compute_snapshot_rate(enemy_nav_snapshot, "nav_path_scan_count")
	var goal_rate := _compute_snapshot_rate(enemy_nav_snapshot, "goal_select_count")
	var path_metric_rate := _compute_snapshot_rate(enemy_nav_snapshot, "path_metric_count")
	var map_get_path_rate := _compute_snapshot_rate(enemy_nav_snapshot, "map_get_path_count")
	var nearby_query_rate := _compute_snapshot_rate(enemy_nav_snapshot, "nearby_enemy_query_count")
	var local_query_rate := _compute_snapshot_rate(enemy_nav_snapshot, "local_enemy_query_count")
	var rank_query_rate := _compute_snapshot_rate(enemy_nav_snapshot, "frontline_rank_query_count")
	var stuck_rate := _compute_snapshot_rate(enemy_nav_snapshot, "stuck_recovery_count")
	var frontline_rejection_rate := _compute_snapshot_rate(enemy_nav_snapshot, "frontline_rejection_count")

	_perf_stats_label.text = "FPS: %d\nFrame: %.1f ms\nEnemies: %d\nProjectiles: %d\nDebug Lines: %d\nNav cache R/U: %d / %d\nNav resolve/s: %.1f | next-step/s: %.1f | path-scan/s: %.1f\nGoals/s: %.1f | direct total: %d | ring total: %d\nFar-goal total: %d | missing-dist total: %d\nPath metrics/s: %.1f | map_get_path/s: %.1f\nNearby/local/rank queries/s: %.1f / %.1f / %.1f\nStuck/s: %.1f | frontline rejects/s: %.1f" % [
		fps,
		frame_ms,
		enemy_count,
		projectile_count,
		debug_line_count,
		int(enemy_nav_snapshot.get("nav_cache_refresh_count", 0)),
		int(enemy_nav_snapshot.get("nav_cache_reuse_count", 0)),
		nav_resolve_rate,
		nav_step_rate,
		nav_path_scan_rate,
		goal_rate,
		int(enemy_nav_snapshot.get("goal_select_direct_count", 0)),
		int(enemy_nav_snapshot.get("goal_select_ring_count", 0)),
		int(enemy_nav_snapshot.get("goal_select_far_candidate_count", 0)),
		int(enemy_nav_snapshot.get("goal_select_missing_distance_count", 0)),
		path_metric_rate,
		map_get_path_rate,
		nearby_query_rate,
		local_query_rate,
		rank_query_rate,
		stuck_rate,
		frontline_rejection_rate,
	]

	if _enemy_nav_log_enabled:
		_append_enemy_nav_log_row(
			fps,
			frame_ms,
			enemy_count,
			projectile_count,
			debug_line_count,
			enemy_nav_snapshot,
			nav_resolve_rate,
			nav_step_rate,
			nav_path_scan_rate,
			goal_rate,
			path_metric_rate,
			map_get_path_rate,
			nearby_query_rate,
			local_query_rate,
			rank_query_rate,
			stuck_rate,
			frontline_rejection_rate
		)

	_previous_enemy_nav_snapshot = enemy_nav_snapshot
	_enemy_nav_rates_ready = true


func _get_child_count_or_zero(node_name: String) -> int:
	var node := get_parent().get_node_or_null(node_name)
	if node == null:
		return 0

	return node.get_child_count()


func _compute_snapshot_rate(snapshot: Dictionary, key: String) -> float:
	if not _enemy_nav_rates_ready:
		return 0.0

	var current_value: int = int(snapshot.get(key, 0))
	var previous_value: int = int(_previous_enemy_nav_snapshot.get(key, 0))
	var delta_value: int = max(current_value - previous_value, 0)
	return float(delta_value) / PERF_REFRESH_INTERVAL_SEC


func _ensure_enemy_nav_log_header() -> void:
	var file := FileAccess.open(ENEMY_NAV_LOG_PATH, FileAccess.READ)
	if file != null and file.get_length() > 0:
		return

	var write_file := FileAccess.open(ENEMY_NAV_LOG_PATH, FileAccess.WRITE)
	if write_file == null:
		return

	write_file.store_line(
		"unix_time,runtime_sec,fps,frame_ms,enemies,projectiles,debug_lines," +
		"nav_cache_refresh_total,nav_cache_reuse_total,nav_resolve_per_sec,nav_step_per_sec,nav_path_scan_per_sec," +
		"goal_select_per_sec,goal_select_direct_total,goal_select_ring_total,goal_select_far_total,goal_select_missing_distance_total," +
		"path_metric_per_sec,map_get_path_per_sec,nearby_query_per_sec,local_query_per_sec,frontline_rank_query_per_sec," +
		"stuck_recovery_per_sec,frontline_reject_per_sec"
	)


func _append_enemy_nav_log_row(
	fps: int,
	frame_ms: float,
	enemy_count: int,
	projectile_count: int,
	debug_line_count: int,
	enemy_nav_snapshot: Dictionary,
	nav_resolve_rate: float,
	nav_step_rate: float,
	nav_path_scan_rate: float,
	goal_rate: float,
	path_metric_rate: float,
	map_get_path_rate: float,
	nearby_query_rate: float,
	local_query_rate: float,
	rank_query_rate: float,
	stuck_rate: float,
	frontline_rejection_rate: float
) -> void:
	_ensure_enemy_nav_log_header()
	var log_file := FileAccess.open(ENEMY_NAV_LOG_PATH, FileAccess.READ_WRITE)
	if log_file == null:
		return

	log_file.seek_end()

	var runtime_sec := 0.0
	if _enemy_nav_log_start_msec > 0:
		runtime_sec = float(Time.get_ticks_msec() - _enemy_nav_log_start_msec) / 1000.0

	var row := PackedStringArray([
		str(Time.get_unix_time_from_system()),
		"%.3f" % runtime_sec,
		str(fps),
		"%.2f" % frame_ms,
		str(enemy_count),
		str(projectile_count),
		str(debug_line_count),
		str(int(enemy_nav_snapshot.get("nav_cache_refresh_count", 0))),
		str(int(enemy_nav_snapshot.get("nav_cache_reuse_count", 0))),
		"%.3f" % nav_resolve_rate,
		"%.3f" % nav_step_rate,
		"%.3f" % nav_path_scan_rate,
		"%.3f" % goal_rate,
		str(int(enemy_nav_snapshot.get("goal_select_direct_count", 0))),
		str(int(enemy_nav_snapshot.get("goal_select_ring_count", 0))),
		str(int(enemy_nav_snapshot.get("goal_select_far_candidate_count", 0))),
		str(int(enemy_nav_snapshot.get("goal_select_missing_distance_count", 0))),
		"%.3f" % path_metric_rate,
		"%.3f" % map_get_path_rate,
		"%.3f" % nearby_query_rate,
		"%.3f" % local_query_rate,
		"%.3f" % rank_query_rate,
		"%.3f" % stuck_rate,
		"%.3f" % frontline_rejection_rate,
	])
	log_file.store_line(",".join(row))
