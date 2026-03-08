extends CanvasLayer

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")

@onready var _panel: PanelContainer = $PanelContainer
@onready var _enemy_status_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyStatusToggle
@onready var _enemy_nav_path_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/EnemyNavPathToggle
@onready var _projectile_line_toggle: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/ProjectileLineToggle

var _menu_open: bool = false
var _enemy_status_enabled: bool = false
var _enemy_nav_path_enabled: bool = false
var _projectile_debug_lines_enabled: bool = false


func _ready() -> void:
	add_to_group("debug_overlay")
	_enemy_status_toggle.toggled.connect(_on_enemy_status_toggled)
	_enemy_nav_path_toggle.toggled.connect(_on_enemy_nav_path_toggled)
	_projectile_line_toggle.toggled.connect(_on_projectile_line_toggled)
	_sync_menu_state()


func toggle_menu() -> void:
	_menu_open = not _menu_open
	_sync_menu_state()


func is_enemy_status_enabled() -> bool:
	return _enemy_status_enabled


func is_enemy_nav_path_enabled() -> bool:
	return _enemy_nav_path_enabled


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


func _sync_menu_state() -> void:
	_panel.visible = _menu_open
	_enemy_status_toggle.button_pressed = _enemy_status_enabled
	_enemy_nav_path_toggle.button_pressed = _enemy_nav_path_enabled
	_projectile_line_toggle.button_pressed = _projectile_debug_lines_enabled


func _on_enemy_status_toggled(enabled: bool) -> void:
	_enemy_status_enabled = enabled


func _on_enemy_nav_path_toggled(enabled: bool) -> void:
	_enemy_nav_path_enabled = enabled


func _on_projectile_line_toggled(enabled: bool) -> void:
	_projectile_debug_lines_enabled = enabled
