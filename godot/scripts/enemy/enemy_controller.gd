extends CharacterBody3D

@export var move_speed: float = 4.5
@export var turn_speed: float = 8.0
@export var target_path: NodePath
@export var debug_enabled: bool = true
@export var show_hp_label: bool = true
@export var max_hp: float = 3.0
@export var desired_stop_distance: float = 1.35
@export var stuck_timeout: float = 0.35
@export var stuck_recovery_duration: float = 0.3
@export var stuck_min_progress_distance: float = 0.02

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _debug_label: Label3D = $DebugLabel3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_node: Node3D
var _last_debug_write_msec: int = 0
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0

const DEBUG_LOG_PATH := "user://debug/enemy_debug.log"
const DEBUG_WRITE_INTERVAL_MSEC := 500


func _ready() -> void:
	_current_hp = max_hp
	_nav_agent.set_navigation_map(get_world_3d().navigation_map)
	_nav_agent.path_desired_distance = 1.0
	_nav_agent.target_desired_distance = desired_stop_distance
	call_deferred("_resolve_target")
	_prepare_debug_log()
	_refresh_label("idle", Vector3.ZERO, 0)


func _resolve_target() -> void:
	if not target_path.is_empty():
		_target_node = get_node_or_null(target_path) as Node3D

	if _target_node == null:
		_target_node = get_tree().get_first_node_in_group("player") as Node3D


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
	else:
		var iteration_id := NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map())
		debug_iteration_id = iteration_id
		if iteration_id == 0:
			velocity.x = 0.0
			velocity.z = 0.0
			debug_state = "nav not ready"
			_update_debug(debug_state, debug_next_position, debug_iteration_id)
			move_and_slide()
			return

		_nav_agent.target_position = _target_node.global_position
		var next_position: Vector3 = _nav_agent.get_next_path_position()
		debug_next_position = next_position
		var horizontal_offset: Vector3 = next_position - global_position
		horizontal_offset.y = 0.0
		var distance_to_target: float = global_position.distance_to(_target_node.global_position)

		if distance_to_target <= desired_stop_distance:
			velocity.x = 0.0
			velocity.z = 0.0
			debug_state = "holding"
		elif _nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0
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

			var target_yaw := atan2(move_direction.x, move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			debug_state = "at next point"

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_stuck_state(delta, pre_move_position, attempted_horizontal_move)
	_update_debug(debug_state, debug_next_position, debug_iteration_id)


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
		_recovery_elapsed = stuck_recovery_duration
		_recovery_sign *= -1.0


func _update_debug(state_text: String, next_position: Vector3, iteration_id: int) -> void:
	var distance_to_target := -1.0
	var distance_to_next: float = global_position.distance_to(next_position)
	if _target_node != null:
		distance_to_target = global_position.distance_to(_target_node.global_position)

	_refresh_label(state_text, next_position, iteration_id, distance_to_target, distance_to_next)

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

	var lines: Array[String] = []
	if show_hp_label:
		lines.append("HP: %.0f/%.0f" % [_current_hp, max_hp])

	if debug_enabled:
		lines.append_array([
			"state: %s" % state_text,
			"iter: %d" % iteration_id,
			"finished: %s" % str(_nav_agent.is_navigation_finished()),
			"stuck: %.2f" % _stuck_elapsed,
			"d_target: %.2f" % distance_to_target,
			"d_next: %.2f" % distance_to_next,
			"next: %.2f, %.2f" % [next_position.x, next_position.z],
		])

	_debug_label.text = "\n".join(lines)


func _prepare_debug_log() -> void:
	if not debug_enabled:
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
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_debug_write_msec < DEBUG_WRITE_INTERVAL_MSEC:
		return

	_last_debug_write_msec = now_msec

	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line(
		"%s | enemy=%s | pos=(%.2f, %.2f, %.2f) | state=%s | iter=%d | finished=%s | d_target=%.2f | d_next=%.2f | next=(%.2f, %.2f, %.2f)" % [
			Time.get_datetime_string_from_system(),
			name,
			global_position.x,
			global_position.y,
			global_position.z,
			state_text,
			iteration_id,
			str(_nav_agent.is_navigation_finished()),
			distance_to_target,
			distance_to_next,
			next_position.x,
			next_position.y,
			next_position.z,
		]
	)
	file.flush()


func apply_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	if _current_hp <= 0.0:
		queue_free()


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	_refresh_label("idle", Vector3.ZERO, 0)


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)
