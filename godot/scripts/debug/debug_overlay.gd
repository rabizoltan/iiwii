extends CanvasLayer

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")

@onready var _panel: PanelContainer = $PanelContainer
@onready var _projectile_line_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/ProjectileLineToggle
@onready var _perf_stats_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PerfStats

var _menu_open: bool = false
var _projectile_debug_lines_enabled: bool = false
var _perf_refresh_remaining: float = 0.0

const PERF_REFRESH_INTERVAL_SEC := 0.25


func _ready() -> void:
	add_to_group("debug_overlay")
	_projectile_line_toggle.toggled.connect(_on_projectile_line_toggled)
	_sync_menu_state()


func toggle_menu() -> void:
	_menu_open = not _menu_open
	if _menu_open:
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


func _on_projectile_line_toggled(enabled: bool) -> void:
	_projectile_debug_lines_enabled = enabled


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


func _get_child_count_or_zero(node_name: String) -> int:
	var node := get_parent().get_node_or_null(node_name)
	if node == null:
		return 0

	return node.get_child_count()
