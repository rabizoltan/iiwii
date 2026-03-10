extends CanvasLayer

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")
const ENEMY_CONTROLLER_SCRIPT := preload("res://scripts/enemy/enemy_controller.gd")
const ENEMY_PROFILE_LOG_PATH := "user://debug/enemy_profile.log"

@onready var _panel: PanelContainer = $PanelContainer
@onready var _enemy_status_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyStatusToggle
@onready var _enemy_nav_path_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyNavPathToggle
@onready var _projectile_line_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/ProjectileLineToggle
@onready var _enemy_profiler_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyProfilerToggle
@onready var _perf_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PerfStats
@onready var _profile_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ProfileStats

var _menu_open: bool = false
var _enemy_status_enabled: bool = false
var _enemy_nav_path_enabled: bool = false
var _projectile_debug_lines_enabled: bool = false
var _enemy_profiling_enabled: bool = false
var _perf_refresh_remaining: float = 0.0
var _profile_log_write_msec: int = 0

const PERF_REFRESH_INTERVAL_SEC := 0.25
const PROFILE_LOG_INTERVAL_MSEC := 1000


func _ready() -> void:
	add_to_group("debug_overlay")
	_enemy_status_toggle.toggled.connect(_on_enemy_status_toggled)
	_enemy_nav_path_toggle.toggled.connect(_on_enemy_nav_path_toggled)
	_projectile_line_toggle.toggled.connect(_on_projectile_line_toggled)
	_enemy_profiler_toggle.toggled.connect(_on_enemy_profiler_toggled)
	_sync_menu_state()
	_prepare_profile_log()


func toggle_menu() -> void:
	_menu_open = not _menu_open
	if _menu_open:
		_refresh_perf_stats()
	_sync_menu_state()


func is_enemy_status_enabled() -> bool:
	return _enemy_status_enabled


func is_enemy_nav_path_enabled() -> bool:
	return _enemy_nav_path_enabled


func is_projectile_debug_lines_enabled() -> bool:
	return _projectile_debug_lines_enabled


func is_enemy_profiling_enabled() -> bool:
	return _enemy_profiling_enabled


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
	if _enemy_profiling_enabled:
		_maybe_write_profile_log()

	if not _menu_open:
		return

	_perf_refresh_remaining = maxf(_perf_refresh_remaining - delta, 0.0)
	if _perf_refresh_remaining > 0.0:
		return

	_refresh_perf_stats()


func _sync_menu_state() -> void:
	_panel.visible = _menu_open
	_enemy_status_toggle.button_pressed = _enemy_status_enabled
	_enemy_nav_path_toggle.button_pressed = _enemy_nav_path_enabled
	_projectile_line_toggle.button_pressed = _projectile_debug_lines_enabled
	_enemy_profiler_toggle.button_pressed = _enemy_profiling_enabled


func _on_enemy_status_toggled(enabled: bool) -> void:
	_enemy_status_enabled = enabled


func _on_enemy_nav_path_toggled(enabled: bool) -> void:
	_enemy_nav_path_enabled = enabled


func _on_projectile_line_toggled(enabled: bool) -> void:
	_projectile_debug_lines_enabled = enabled


func _on_enemy_profiler_toggled(enabled: bool) -> void:
	_enemy_profiling_enabled = enabled
	ENEMY_CONTROLLER_SCRIPT.set_profiling_enabled(enabled)
	if enabled:
		_prepare_profile_log()
	else:
		_profile_stats_label.text = "Enemy profiling disabled."


func _refresh_perf_stats() -> void:
	_perf_refresh_remaining = PERF_REFRESH_INTERVAL_SEC
	if _perf_stats_label == null:
		return

	var fps: int = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(float(fps), 1.0)
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var projectile_count := _get_child_count_or_zero("Projectiles")
	var debug_line_count := _get_child_count_or_zero("DebugWorld")

	_perf_stats_label.text = "FPS: %d\nFrame: %.1f ms\nEnemies: %d\nProjectiles: %d\nDebug Lines: %d" % [
		fps,
		frame_ms,
		enemy_count,
		projectile_count,
		debug_line_count,
	]
	_refresh_profile_stats()


func _get_child_count_or_zero(node_name: String) -> int:
	var node := get_parent().get_node_or_null(node_name)
	if node == null:
		return 0

	return node.get_child_count()


func _refresh_profile_stats() -> void:
	if _profile_stats_label == null:
		return

	if not _enemy_profiling_enabled:
		_profile_stats_label.text = "Enemy profiling disabled."
		return

	var snapshot: Dictionary = ENEMY_CONTROLLER_SCRIPT.get_profile_snapshot()
	_profile_stats_label.text = _format_profile_snapshot(snapshot)


func _format_profile_snapshot(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return "Enemy profiling warming up..."

	return "Window: %.2fs\nPhysics: %.2f ms total | %.3f ms avg | calls %d\ngoal: %.2f ms (%s)\nyield: %.2f ms (%s)\nnavq: %.2f ms (%s)\nmove: %.2f ms (%s)\nlabel: %.2f ms (%s)\nnavdbg: %.2f ms (%s)\nenemies: %d | goals %d | yields %d" % [
		float(snapshot.get("window_sec", 0.0)),
		float(snapshot.get("physics_total_ms", 0.0)),
		float(snapshot.get("physics_avg_ms", 0.0)),
		int(snapshot.get("physics_calls", 0)),
		float(snapshot.get("goal_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "goal_share"),
		float(snapshot.get("yield_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "yield_share"),
		float(snapshot.get("nav_query_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "nav_query_share"),
		float(snapshot.get("move_slide_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "move_slide_share"),
		float(snapshot.get("label_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "label_share"),
		float(snapshot.get("nav_debug_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "nav_debug_share"),
		int(snapshot.get("enemy_count", 0)),
		int(snapshot.get("goal_calls", 0)),
		int(snapshot.get("yield_calls", 0)),
	]


func _snapshot_percent_text(snapshot: Dictionary, key: String) -> String:
	return "%.0f%%" % (float(snapshot.get(key, 0.0)) * 100.0)


func _prepare_profile_log() -> void:
	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(ENEMY_PROFILE_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- enemy profile session start ---")
	file.flush()
	_profile_log_write_msec = Time.get_ticks_msec()


func _maybe_write_profile_log() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _profile_log_write_msec < PROFILE_LOG_INTERVAL_MSEC:
		return

	_profile_log_write_msec = now_msec
	var snapshot: Dictionary = ENEMY_CONTROLLER_SCRIPT.get_profile_snapshot()
	if snapshot.is_empty():
		return

	var file := FileAccess.open(ENEMY_PROFILE_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line(
		"%s | window=%.2fs | enemies=%d | physics_total_ms=%.2f | physics_avg_ms=%.3f | goal_ms=%.2f | goal_share=%.2f | yield_ms=%.2f | yield_share=%.2f | nav_query_ms=%.2f | nav_query_share=%.2f | move_slide_ms=%.2f | move_slide_share=%.2f | label_ms=%.2f | label_share=%.2f | nav_debug_ms=%.2f | nav_debug_share=%.2f | physics_calls=%d | goal_calls=%d | yield_calls=%d" % [
			Time.get_datetime_string_from_system(),
			float(snapshot.get("window_sec", 0.0)),
			int(snapshot.get("enemy_count", 0)),
			float(snapshot.get("physics_total_ms", 0.0)),
			float(snapshot.get("physics_avg_ms", 0.0)),
			float(snapshot.get("goal_total_ms", 0.0)),
			float(snapshot.get("goal_share", 0.0)),
			float(snapshot.get("yield_total_ms", 0.0)),
			float(snapshot.get("yield_share", 0.0)),
			float(snapshot.get("nav_query_total_ms", 0.0)),
			float(snapshot.get("nav_query_share", 0.0)),
			float(snapshot.get("move_slide_total_ms", 0.0)),
			float(snapshot.get("move_slide_share", 0.0)),
			float(snapshot.get("label_total_ms", 0.0)),
			float(snapshot.get("label_share", 0.0)),
			float(snapshot.get("nav_debug_total_ms", 0.0)),
			float(snapshot.get("nav_debug_share", 0.0)),
			int(snapshot.get("physics_calls", 0)),
			int(snapshot.get("goal_calls", 0)),
			int(snapshot.get("yield_calls", 0)),
		]
	)
	file.flush()
