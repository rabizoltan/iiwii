extends CanvasLayer

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")
const ENEMY_CONTROLLER_SCRIPT := preload("res://scripts/enemy/enemy_controller.gd")
const ENEMY_PROFILE_LOG_PATH := "user://debug/enemy_profile.log"

@onready var _panel: PanelContainer = $PanelContainer
@onready var _enemy_nav_path_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyNavPathToggle
@onready var _projectile_line_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/ProjectileLineToggle
@onready var _enemy_profiler_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyProfilerToggle
@onready var _perf_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PerfStats
@onready var _profile_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ProfileStats

var _menu_open: bool = false
var _enemy_nav_path_enabled: bool = false
var _projectile_debug_lines_enabled: bool = false
var _enemy_profiling_enabled: bool = false
var _perf_refresh_remaining: float = 0.0
var _profile_log_write_msec: int = 0

const PERF_REFRESH_INTERVAL_SEC := 0.25
const PROFILE_LOG_INTERVAL_MSEC := 1000


func _ready() -> void:
	add_to_group("debug_overlay")
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
	_enemy_nav_path_toggle.button_pressed = _enemy_nav_path_enabled
	_projectile_line_toggle.button_pressed = _projectile_debug_lines_enabled
	_enemy_profiler_toggle.button_pressed = _enemy_profiling_enabled


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

	return """Window: %.2fs
Physics: %.2f ms total | %.3f ms avg | p50 %.3f | p90 %.3f | p95 %.3f | p99 %.3f | calls %d
prep: %.2f ms (%s)
horiz: %.2f ms (%s)
state: %.2f ms (%s)
melee: %.2f ms (%s)
motion: %.2f ms (%s)
final: %.2f ms (%s)
stuck: %.2f ms (%s)
upd_dbg: %.2f ms (%s)
local: %.2f ms (%s)
nearby: %.2f ms (%s)
front: %.2f ms (%s)
goal: %.2f ms (%s)
gpath: %.2f ms (%s)
yield: %.2f ms (%s)
cadj: %.2f ms (%s)
infl: %.2f ms (%s)
navq: %.2f ms (%s)
snap: %.2f ms (%s)
move: %.2f ms (%s)
navdbg: %.2f ms (%s)
enemies: %d | goals %d | yields %d
goal chk/trig/s/f/fb: %d/%d/%d/%d/%d
nav hit/ref: %d/%d | front %d | cadj %d
states a/q/c/h: %d/%d/%d/%d
move/idle: %d/%d
queue enter/reuse/reject/acap: %d/%d/%d/%d
crowd cache h/m: %d/%d | local %d | nearby %d""" % [
		float(snapshot.get("window_sec", 0.0)),
		float(snapshot.get("physics_total_ms", 0.0)),
		float(snapshot.get("physics_avg_ms", 0.0)),
		float(snapshot.get("physics_p50_ms", 0.0)),
		float(snapshot.get("physics_p90_ms", 0.0)),
		float(snapshot.get("physics_p95_ms", 0.0)),
		float(snapshot.get("physics_p99_ms", 0.0)),
		int(snapshot.get("physics_calls", 0)),
		float(snapshot.get("prepare_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "prepare_share"),
		float(snapshot.get("horizontal_phase_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "horizontal_phase_share"),
		float(snapshot.get("state_dispatch_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "state_dispatch_share"),
		float(snapshot.get("melee_state_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "melee_state_share"),
		float(snapshot.get("state_motion_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "state_motion_share"),
		float(snapshot.get("finalize_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "finalize_share"),
		float(snapshot.get("stuck_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "stuck_share"),
		float(snapshot.get("update_debug_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "update_debug_share"),
		float(snapshot.get("local_enemy_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "local_enemy_share"),
		float(snapshot.get("nearby_enemy_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "nearby_enemy_share"),
		float(snapshot.get("frontline_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "frontline_share"),
		float(snapshot.get("goal_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "goal_share"),
		float(snapshot.get("goal_path_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "goal_path_share"),
		float(snapshot.get("yield_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "yield_share"),
		float(snapshot.get("close_adjust_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "close_adjust_share"),
		float(snapshot.get("influence_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "influence_share"),
		float(snapshot.get("nav_query_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "nav_query_share"),
		float(snapshot.get("snapshot_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "snapshot_share"),
		float(snapshot.get("move_slide_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "move_slide_share"),
		float(snapshot.get("nav_debug_total_ms", 0.0)),
		_snapshot_percent_text(snapshot, "nav_debug_share"),
		int(snapshot.get("enemy_count", 0)),
		int(snapshot.get("goal_calls", 0)),
		int(snapshot.get("yield_calls", 0)),
		int(snapshot.get("goal_refresh_checks", 0)),
		int(snapshot.get("goal_refresh_triggers", 0)),
		int(snapshot.get("goal_selection_successes", 0)),
		int(snapshot.get("goal_selection_failures", 0)),
		int(snapshot.get("goal_selection_fallbacks", 0)),
		int(snapshot.get("nav_cache_hits", 0)),
		int(snapshot.get("nav_cache_refreshes", 0)),
		int(snapshot.get("frontline_checks", 0)),
		int(snapshot.get("close_adjust_calls", 0)),
		int(snapshot.get("state_approach_frames", 0)),
		int(snapshot.get("state_queue_frames", 0)),
		int(snapshot.get("state_close_adjust_frames", 0)),
		int(snapshot.get("state_melee_hold_frames", 0)),
		int(snapshot.get("state_move_frames", 0)),
		int(snapshot.get("state_idle_frames", 0)),
		int(snapshot.get("queue_entries", 0)),
		int(snapshot.get("queue_hold_reuses", 0)),
		int(snapshot.get("frontline_rejections", 0)),
		int(snapshot.get("approach_cap_rejections", 0)),
		int(snapshot.get("crowd_cache_hits", 0)),
		int(snapshot.get("crowd_cache_misses", 0)),
		int(snapshot.get("crowd_local_queries", 0)),
		int(snapshot.get("crowd_nearby_queries", 0)),
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
		"%s | window=%.2fs | enemies=%d | physics_total_ms=%.2f | physics_avg_ms=%.3f | physics_p50_ms=%.3f | physics_p90_ms=%.3f | physics_p95_ms=%.3f | physics_p99_ms=%.3f | prepare_ms=%.2f | prepare_share=%.2f | horizontal_phase_ms=%.2f | horizontal_phase_share=%.2f | state_dispatch_ms=%.2f | state_dispatch_share=%.2f | melee_state_ms=%.2f | melee_state_share=%.2f | state_motion_ms=%.2f | state_motion_share=%.2f | finalize_ms=%.2f | finalize_share=%.2f | stuck_ms=%.2f | stuck_share=%.2f | update_debug_ms=%.2f | update_debug_share=%.2f | local_enemy_ms=%.2f | local_enemy_share=%.2f | nearby_enemy_ms=%.2f | nearby_enemy_share=%.2f | frontline_ms=%.2f | frontline_share=%.2f | goal_ms=%.2f | goal_share=%.2f | goal_path_ms=%.2f | goal_path_share=%.2f | yield_ms=%.2f | yield_share=%.2f | close_adjust_ms=%.2f | close_adjust_share=%.2f | influence_ms=%.2f | influence_share=%.2f | nav_query_ms=%.2f | nav_query_share=%.2f | snapshot_ms=%.2f | snapshot_share=%.2f | move_slide_ms=%.2f | move_slide_share=%.2f | nav_debug_ms=%.2f | nav_debug_share=%.2f | goal_refresh_checks=%d | goal_refresh_triggers=%d | goal_successes=%d | goal_failures=%d | goal_fallbacks=%d | nav_cache_hits=%d | nav_cache_refreshes=%d | frontline_checks=%d | close_adjust_calls=%d | state_approach_frames=%d | state_queue_frames=%d | state_close_adjust_frames=%d | state_melee_hold_frames=%d | state_move_frames=%d | state_idle_frames=%d | queue_entries=%d | queue_hold_reuses=%d | frontline_rejections=%d | approach_cap_rejections=%d | crowd_cache_hits=%d | crowd_cache_misses=%d | crowd_local_queries=%d | crowd_nearby_queries=%d | physics_calls=%d | goal_calls=%d | yield_calls=%d" % [
			Time.get_datetime_string_from_system(),
			float(snapshot.get("window_sec", 0.0)),
			int(snapshot.get("enemy_count", 0)),
			float(snapshot.get("physics_total_ms", 0.0)),
			float(snapshot.get("physics_avg_ms", 0.0)),
			float(snapshot.get("physics_p50_ms", 0.0)),
			float(snapshot.get("physics_p90_ms", 0.0)),
			float(snapshot.get("physics_p95_ms", 0.0)),
			float(snapshot.get("physics_p99_ms", 0.0)),
			float(snapshot.get("prepare_total_ms", 0.0)),
			float(snapshot.get("prepare_share", 0.0)),
			float(snapshot.get("horizontal_phase_total_ms", 0.0)),
			float(snapshot.get("horizontal_phase_share", 0.0)),
			float(snapshot.get("state_dispatch_total_ms", 0.0)),
			float(snapshot.get("state_dispatch_share", 0.0)),
			float(snapshot.get("melee_state_total_ms", 0.0)),
			float(snapshot.get("melee_state_share", 0.0)),
			float(snapshot.get("state_motion_total_ms", 0.0)),
			float(snapshot.get("state_motion_share", 0.0)),
			float(snapshot.get("finalize_total_ms", 0.0)),
			float(snapshot.get("finalize_share", 0.0)),
			float(snapshot.get("stuck_total_ms", 0.0)),
			float(snapshot.get("stuck_share", 0.0)),
			float(snapshot.get("update_debug_total_ms", 0.0)),
			float(snapshot.get("update_debug_share", 0.0)),
			float(snapshot.get("local_enemy_total_ms", 0.0)),
			float(snapshot.get("local_enemy_share", 0.0)),
			float(snapshot.get("nearby_enemy_total_ms", 0.0)),
			float(snapshot.get("nearby_enemy_share", 0.0)),
			float(snapshot.get("frontline_total_ms", 0.0)),
			float(snapshot.get("frontline_share", 0.0)),
			float(snapshot.get("goal_total_ms", 0.0)),
			float(snapshot.get("goal_share", 0.0)),
			float(snapshot.get("goal_path_total_ms", 0.0)),
			float(snapshot.get("goal_path_share", 0.0)),
			float(snapshot.get("yield_total_ms", 0.0)),
			float(snapshot.get("yield_share", 0.0)),
			float(snapshot.get("close_adjust_total_ms", 0.0)),
			float(snapshot.get("close_adjust_share", 0.0)),
			float(snapshot.get("influence_total_ms", 0.0)),
			float(snapshot.get("influence_share", 0.0)),
			float(snapshot.get("nav_query_total_ms", 0.0)),
			float(snapshot.get("nav_query_share", 0.0)),
			float(snapshot.get("snapshot_total_ms", 0.0)),
			float(snapshot.get("snapshot_share", 0.0)),
			float(snapshot.get("move_slide_total_ms", 0.0)),
			float(snapshot.get("move_slide_share", 0.0)),
			float(snapshot.get("nav_debug_total_ms", 0.0)),
			float(snapshot.get("nav_debug_share", 0.0)),
			int(snapshot.get("goal_refresh_checks", 0)),
			int(snapshot.get("goal_refresh_triggers", 0)),
			int(snapshot.get("goal_selection_successes", 0)),
			int(snapshot.get("goal_selection_failures", 0)),
			int(snapshot.get("goal_selection_fallbacks", 0)),
			int(snapshot.get("nav_cache_hits", 0)),
			int(snapshot.get("nav_cache_refreshes", 0)),
			int(snapshot.get("frontline_checks", 0)),
			int(snapshot.get("close_adjust_calls", 0)),
			int(snapshot.get("state_approach_frames", 0)),
			int(snapshot.get("state_queue_frames", 0)),
			int(snapshot.get("state_close_adjust_frames", 0)),
			int(snapshot.get("state_melee_hold_frames", 0)),
			int(snapshot.get("state_move_frames", 0)),
			int(snapshot.get("state_idle_frames", 0)),
			int(snapshot.get("queue_entries", 0)),
			int(snapshot.get("queue_hold_reuses", 0)),
			int(snapshot.get("frontline_rejections", 0)),
			int(snapshot.get("approach_cap_rejections", 0)),
			int(snapshot.get("crowd_cache_hits", 0)),
			int(snapshot.get("crowd_cache_misses", 0)),
			int(snapshot.get("crowd_local_queries", 0)),
			int(snapshot.get("crowd_nearby_queries", 0)),
			int(snapshot.get("physics_calls", 0)),
			int(snapshot.get("goal_calls", 0)),
			int(snapshot.get("yield_calls", 0)),
		]
	)
	file.flush()
