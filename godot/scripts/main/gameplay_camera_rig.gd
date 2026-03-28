extends Node3D

@export var target_path: NodePath
@export var follow_lerp_speed: float = 10.0
@export var rotation_drag_degrees_per_pixel: float = 0.25
@export var pitch_degrees: float = 52.0
@export var default_yaw_degrees: float = 0.0
@export var min_zoom_distance: float = 10.0
@export var max_zoom_distance: float = 30.0
@export var default_zoom_distance: float = 26.0
@export var zoom_step: float = 1.5
@export var zoom_lerp_speed: float = 12.0

var _target: Node3D
var _yaw_radians: float = 0.0
var _zoom_distance: float = 0.0
var _target_zoom_distance: float = 0.0
var _is_rotating_from_mouse: bool = false

@onready var _yaw_pivot: Node3D = $CameraYawPivot
@onready var _camera: Camera3D = $CameraYawPivot/Camera3D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_yaw_radians = deg_to_rad(default_yaw_degrees)
	_zoom_distance = clampf(default_zoom_distance, min_zoom_distance, max_zoom_distance)
	_target_zoom_distance = _zoom_distance

	if _target != null:
		global_position = _target.global_position

	_apply_camera_transform()


func _physics_process(delta: float) -> void:
	_follow_target(delta)
	_update_zoom(delta)
	_apply_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_rotating_from_mouse = mouse_button_event.pressed
			return
		if mouse_button_event.pressed:
			if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
				return
			if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
				return

	if event is InputEventMouseMotion and _is_rotating_from_mouse:
		var mouse_motion := event as InputEventMouseMotion
		_yaw_radians -= deg_to_rad(mouse_motion.relative.x * rotation_drag_degrees_per_pixel)
		return

	if event.is_action_pressed("camera_zoom_in"):
		zoom_in()
	elif event.is_action_pressed("camera_zoom_out"):
		zoom_out()


func _follow_target(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_node_or_null(target_path) as Node3D
		if _target == null:
			return

	global_position = global_position.lerp(_target.global_position, clampf(follow_lerp_speed * delta, 0.0, 1.0))


func _update_zoom(delta: float) -> void:
	_zoom_distance = lerpf(_zoom_distance, _target_zoom_distance, clampf(zoom_lerp_speed * delta, 0.0, 1.0))


func _apply_camera_transform() -> void:
	_yaw_pivot.rotation.y = _yaw_radians

	var pitch_radians := deg_to_rad(pitch_degrees)
	var height := sin(pitch_radians) * _zoom_distance
	var distance := cos(pitch_radians) * _zoom_distance
	_camera.position = Vector3(0.0, height, distance)
	_camera.rotation = Vector3(-pitch_radians, 0.0, 0.0)


func _adjust_zoom(delta_amount: float) -> void:
	_target_zoom_distance = clampf(_target_zoom_distance + delta_amount, min_zoom_distance, max_zoom_distance)


func zoom_in() -> void:
	_adjust_zoom(-zoom_step)


func zoom_out() -> void:
	_adjust_zoom(zoom_step)
