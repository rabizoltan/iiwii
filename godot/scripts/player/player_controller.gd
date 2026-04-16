extends CharacterBody3D

enum MobilityProfile {
	DODGE,
	DASH,
}

@export var move_speed: float = 7.0
@export var turn_speed: float = 10.0

@export_range(0.1, 1.0) var crouch_speed_multiplier: float = 0.6
@export var crouch_collision_height: float = 0.95
@export var crouch_collision_center_y: float = 0.5
@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 0.5
@export var aim_collision_mask: int = 3
@export var aim_ray_length: float = 1000.0
@export var mobility_profile: MobilityProfile = MobilityProfile.DODGE
@export var dodge_distance: float = 2.1
@export var dodge_duration: float = 0.18
@export var dodge_cooldown: float = 0.75
@export_range(0.0, 1.0) var dodge_enemy_ghost_start: float = 0.0
@export_range(0.0, 1.0) var dodge_enemy_ghost_end: float = 1.0
@export var dash_distance: float = 4.4
@export var dash_duration: float = 0.26
@export var dash_cooldown: float = 1.25
@export_range(0.0, 1.0) var dash_enemy_ghost_start: float = 0.0
@export_range(0.0, 1.0) var dash_enemy_ghost_end: float = 1.0
@export var vault_duration: float = 0.6
@export var vault_activation_distance: float = 1.2
@export_range(0.0, 89.0) var vault_facing_angle_degrees: float = 65.0
@export var vault_arc_min_height: float = 0.2
@export var vault_arc_max_height: float = 2.5
@export var vault_same_floor_tolerance: float = 0.6

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_cooldown_remaining: float = 0.0
var _mobility_cooldown_remaining: float = 0.0
var _active_vault_triggers: Array[VaultTrigger] = []
var _last_move_direction: Vector3 = Vector3.FORWARD
var _mobility_active: bool = false
var _mobility_elapsed: float = 0.0
var _mobility_duration: float = 0.0
var _mobility_direction: Vector3 = Vector3.ZERO
var _mobility_speed: float = 0.0
var _mobility_distance_remaining: float = 0.0
var _mobility_ghost_active: bool = false
var _mobility_enemy_exceptions: Array[PhysicsBody3D] = []
var _vault_active: bool = false
var _vault_elapsed: float = 0.0
var _vault_duration_current: float = 0.0
var _vault_start_position: Vector3 = Vector3.ZERO
var _vault_end_position: Vector3 = Vector3.ZERO
var _vault_direction: Vector3 = Vector3.ZERO
var _vault_arc_height: float = 0.0
var _vault_ghost_active: bool = false

var _crouching: bool = false
var _standing_collision_height: float = 0.0
var _standing_collision_center_y: float = 0.0
var _body_mesh_base_scale: Vector3 = Vector3.ONE

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D as CollisionShape3D
@onready var _body_mesh: MeshInstance3D = $BodyMesh as MeshInstance3D
@onready var _facing_marker: Node3D = $FacingMarker as Node3D
@onready var _projectile_spawn: Marker3D = $ProjectileSpawn as Marker3D


func _ready() -> void:
	if _collision_shape != null and _collision_shape.shape != null:
		_collision_shape.shape = _collision_shape.shape.duplicate()
		var standing_capsule: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D
		if standing_capsule != null:
			_standing_collision_height = standing_capsule.height
			_standing_collision_center_y = _collision_shape.position.y

	if _body_mesh != null:
		_body_mesh_base_scale = _body_mesh.scale


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction: Vector3 = _get_move_direction(input_vector)

	if move_direction.length_squared() > 0.0:
		_last_move_direction = move_direction.normalized()

	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	if _mobility_cooldown_remaining > 0.0:
		_mobility_cooldown_remaining = maxf(_mobility_cooldown_remaining - delta, 0.0)

	if _vault_active:
		_process_vault(delta)
		return

	if _mobility_active:
		_process_mobility(delta)
		return

	_update_crouch_state()

	if Input.is_action_just_pressed("dodge"):
		if _try_start_mobility(move_direction):
			_process_mobility(delta)
			return

	if Input.is_action_just_pressed("vault"):
		if _try_start_vault(move_direction):
			_process_vault(delta)
			return

	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		var target_speed: float = move_speed * (crouch_speed_multiplier if _crouching else 1.0)
		var target_velocity: Vector3 = move_direction * target_speed
		velocity.x = target_velocity.x
		velocity.z = target_velocity.z

		var target_yaw: float = _yaw_from_direction(move_direction)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if Input.is_action_just_pressed("attack") and not _crouching:
		_try_attack()


func register_vault_trigger(trigger: VaultTrigger) -> void:
	if trigger == null or _active_vault_triggers.has(trigger):
		return

	_active_vault_triggers.append(trigger)


func unregister_vault_trigger(trigger: VaultTrigger) -> void:
	_active_vault_triggers.erase(trigger)


func _try_start_vault(move_direction: Vector3) -> bool:
	if _vault_active or _mobility_active or _crouching or not is_on_floor():
		return false

	if move_direction.length_squared() <= 0.0:
		return false

	var movement_direction: Vector3 = move_direction.normalized()
	var min_alignment_dot: float = cos(deg_to_rad(vault_facing_angle_degrees))
	var best_candidate: Dictionary = {}
	var best_distance_sq: float = INF

	for trigger in _active_vault_triggers:
		if trigger == null or not is_instance_valid(trigger):
			continue

		var candidate: Dictionary = trigger.get_candidate(
			self,
			movement_direction,
			min_alignment_dot,
			vault_activation_distance,
			vault_same_floor_tolerance
		)
		if candidate.is_empty():
			continue

		var distance_sq: float = float(candidate["distance_sq"])
		if distance_sq < best_distance_sq:
			best_candidate = candidate
			best_distance_sq = distance_sq

	if best_candidate.is_empty():
		return false

	var duration_override: float = float(best_candidate["duration_override"])
	_vault_duration_current = duration_override if duration_override > 0.0 else vault_duration
	if _vault_duration_current <= 0.0:
		return false

	_vault_active = true
	_vault_elapsed = 0.0
	_vault_start_position = global_position
	_vault_end_position = best_candidate["landing_position"]
	_vault_direction = best_candidate["travel_direction"]
	_vault_arc_height = clampf(float(best_candidate["arc_height"]), vault_arc_min_height, vault_arc_max_height)
	velocity = Vector3.ZERO
	rotation.y = _yaw_from_direction(_vault_direction)
	_set_vault_enemy_ghosting(true)
	return true


func _try_attack() -> void:
	if projectile_scene == null or _attack_cooldown_remaining > 0.0 or _crouching:
		return

	var aim_target: Dictionary = _resolve_aim_target()
	if aim_target.is_empty():
		return

	var spawn_marker: Marker3D = _projectile_spawn
	if spawn_marker == null:
		return

	var target_position: Vector3 = aim_target["position"]
	var shot_direction: Vector3 = target_position - spawn_marker.global_position
	if shot_direction.length_squared() <= 0.0:
		return

	var projectile: Node = projectile_scene.instantiate()
	if projectile == null:
		return

	var projectile_parent: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene

	projectile_parent.add_child(projectile)

	if projectile is Node3D:
		(projectile as Node3D).global_position = spawn_marker.global_position

	if projectile.has_method("initialize"):
		projectile.initialize(shot_direction, target_position, get_rid())

	_attack_cooldown_remaining = attack_cooldown


func _resolve_aim_target() -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return {}

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * aim_ray_length

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, aim_collision_mask, [get_rid()])
	query.collide_with_areas = false
	query.hit_back_faces = true

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return {}

	if not result.has("collider"):
		return {}

	var collider: Object = result["collider"] as Object
	if collider == self:
		return {}

	return {
		"position": result["position"],
		"collider": collider,
	}


func _try_start_mobility(move_direction: Vector3) -> bool:
	if _mobility_active or _vault_active or _crouching or _mobility_cooldown_remaining > 0.0:
		return false

	var direction: Vector3 = _resolve_mobility_direction(move_direction)
	if direction.length_squared() <= 0.0:
		return false

	var profile: Dictionary = _get_current_mobility_profile()
	var duration: float = float(profile["duration"])
	var distance: float = float(profile["distance"])
	if duration <= 0.0 or distance <= 0.0:
		return false

	_mobility_active = true
	_mobility_elapsed = 0.0
	_mobility_duration = duration
	_mobility_direction = direction
	_mobility_speed = distance / duration
	_mobility_distance_remaining = distance
	_mobility_cooldown_remaining = float(profile["cooldown"])
	velocity = Vector3.ZERO
	rotation.y = _yaw_from_direction(direction)
	_update_mobility_enemy_ghosting(0.0)
	return true


func _process_mobility(delta: float) -> void:
	_mobility_elapsed = minf(_mobility_elapsed + delta, _mobility_duration)
	var progress: float = _mobility_elapsed / maxf(_mobility_duration, 0.0001)
	var frame_distance: float = minf(_mobility_speed * delta, _mobility_distance_remaining)
	_mobility_distance_remaining = maxf(_mobility_distance_remaining - frame_distance, 0.0)
	velocity.x = _mobility_direction.x * _mobility_speed
	velocity.z = _mobility_direction.z * _mobility_speed

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	_update_mobility_enemy_ghosting(progress)
	move_and_slide()

	if _mobility_elapsed >= _mobility_duration or _mobility_distance_remaining <= 0.0:
		_finish_mobility()


func _finish_mobility() -> void:
	_mobility_active = false
	_mobility_elapsed = 0.0
	_mobility_duration = 0.0
	_mobility_direction = Vector3.ZERO
	_mobility_speed = 0.0
	_mobility_distance_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_update_mobility_enemy_ghosting(1.0)
	_clear_mobility_enemy_exceptions()


func _process_vault(delta: float) -> void:
	_vault_elapsed = minf(_vault_elapsed + delta, _vault_duration_current)
	var progress: float = _vault_elapsed / maxf(_vault_duration_current, 0.0001)
	var base_position: Vector3 = _vault_start_position.lerp(_vault_end_position, progress)
	var arc_offset: float = sin(progress * PI) * _vault_arc_height
	var target_position: Vector3 = base_position
	target_position.y += arc_offset

	rotation.y = _yaw_from_direction(_vault_direction)
	global_position = target_position
	velocity = Vector3.ZERO

	if _vault_elapsed >= _vault_duration_current:
		_finish_vault()


func _finish_vault() -> void:
	velocity = Vector3.ZERO
	_vault_active = false
	_vault_elapsed = 0.0
	_vault_duration_current = 0.0
	_vault_start_position = Vector3.ZERO
	_vault_end_position = Vector3.ZERO
	_vault_direction = Vector3.ZERO
	_vault_arc_height = 0.0
	_set_vault_enemy_ghosting(false)
	_resolve_enemy_overlap_after_vault()


func _set_vault_enemy_ghosting(active: bool) -> void:
	if _vault_ghost_active == active:
		return

	_vault_ghost_active = active
	if _vault_ghost_active:
		_apply_mobility_enemy_exceptions()
	else:
		_clear_mobility_enemy_exceptions()


func _resolve_enemy_overlap_after_vault() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_body: PhysicsBody3D = enemy as PhysicsBody3D
		if enemy_body == null or not is_instance_valid(enemy_body):
			continue

		var to_player: Vector3 = global_position - enemy_body.global_position
		to_player.y = 0.0
		var distance: float = to_player.length()
		if distance >= 0.9:
			continue

		var push_direction: Vector3 = to_player.normalized() if distance > 0.001 else _resolve_mobility_direction(_last_move_direction)
		var push_amount: float = minf(0.2, 0.9 - distance)
		global_position += push_direction * push_amount

func _update_crouch_state() -> void:
	if Input.is_action_pressed("crouch"):
		_set_crouching(true)
		return

	if _crouching and _can_stand():
		_set_crouching(false)


func _set_crouching(active: bool) -> void:
	if _crouching == active:
		return

	_crouching = active
	_apply_crouch_collision(active)
	_apply_crouch_presentation(active)


func _apply_crouch_collision(active: bool) -> void:
	if _collision_shape == null:
		return

	var capsule: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return

	if not active and _standing_collision_height <= 0.0:
		return

	capsule.height = crouch_collision_height if active else _standing_collision_height
	var collision_position: Vector3 = _collision_shape.position
	collision_position.y = crouch_collision_center_y if active else _standing_collision_center_y
	_collision_shape.position = collision_position


func _apply_crouch_presentation(active: bool) -> void:
	if _body_mesh != null and _standing_collision_height > 0.0:
		var mesh_scale: Vector3 = _body_mesh_base_scale
		if active:
			mesh_scale.y *= crouch_collision_height / _standing_collision_height
		_body_mesh.scale = mesh_scale
		_body_mesh.position.y = crouch_collision_center_y if active else _standing_collision_center_y

	if _facing_marker != null:
		var marker_position: Vector3 = _facing_marker.position
		marker_position.y = 0.58 if active else 1.05
		_facing_marker.position = marker_position


func _can_stand() -> bool:
	if _collision_shape == null:
		return true

	if _standing_collision_height <= 0.0:
		return true

	var standing_top: float = _standing_collision_center_y + _standing_collision_height * 0.5
	var crouch_top: float = crouch_collision_center_y + crouch_collision_height * 0.5
	var clearance_height: float = standing_top - crouch_top
	if clearance_height <= 0.0:
		return true

	var current_capsule: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D
	if current_capsule == null:
		return true

	var upper_clearance_shape := CylinderShape3D.new()
	upper_clearance_shape.radius = current_capsule.radius
	upper_clearance_shape.height = clearance_height

	var shape_position := Vector3(_collision_shape.position.x, crouch_top + clearance_height * 0.5, _collision_shape.position.z)
	var shape_transform := global_transform * Transform3D(Basis.IDENTITY, shape_position)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = upper_clearance_shape
	query.transform = shape_transform
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _resolve_mobility_direction(move_direction: Vector3) -> Vector3:
	if move_direction.length_squared() > 0.0:
		return move_direction.normalized()

	if _last_move_direction.length_squared() > 0.0:
		return _last_move_direction.normalized()

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0:
		return forward.normalized()

	return Vector3.FORWARD


func _yaw_from_direction(direction: Vector3) -> float:
	var horizontal_direction: Vector3 = direction
	horizontal_direction.y = 0.0
	if horizontal_direction.length_squared() <= 0.0:
		return rotation.y

	horizontal_direction = horizontal_direction.normalized()
	return atan2(-horizontal_direction.x, -horizontal_direction.z)


func _get_current_mobility_profile() -> Dictionary:
	match mobility_profile:
		MobilityProfile.DASH:
			return {
				"distance": dash_distance,
				"duration": dash_duration,
				"cooldown": dash_cooldown,
				"ghost_start": dash_enemy_ghost_start,
				"ghost_end": dash_enemy_ghost_end,
			}
		_:
			return {
				"distance": dodge_distance,
				"duration": dodge_duration,
				"cooldown": dodge_cooldown,
				"ghost_start": dodge_enemy_ghost_start,
				"ghost_end": dodge_enemy_ghost_end,
			}


func _update_mobility_enemy_ghosting(progress: float) -> void:
	var profile: Dictionary = _get_current_mobility_profile()
	var ghost_start: float = float(profile["ghost_start"])
	var ghost_end: float = float(profile["ghost_end"])
	var should_ghost: bool = progress >= ghost_start and progress <= ghost_end
	if should_ghost == _mobility_ghost_active:
		return

	_mobility_ghost_active = should_ghost
	if _mobility_ghost_active:
		_apply_mobility_enemy_exceptions()
	else:
		_clear_mobility_enemy_exceptions()


func _apply_mobility_enemy_exceptions() -> void:
	_clear_mobility_enemy_exceptions()

	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_body: PhysicsBody3D = enemy as PhysicsBody3D
		if enemy_body == null:
			continue

		add_collision_exception_with(enemy_body)
		enemy_body.add_collision_exception_with(self)
		_mobility_enemy_exceptions.append(enemy_body)


func _clear_mobility_enemy_exceptions() -> void:
	for enemy_body in _mobility_enemy_exceptions:
		if enemy_body == null or not is_instance_valid(enemy_body):
			continue

		remove_collision_exception_with(enemy_body)
		enemy_body.remove_collision_exception_with(self)

	_mobility_enemy_exceptions.clear()


func _get_move_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() <= 0.0:
		return Vector3.ZERO

	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input_vector.x, 0.0, input_vector.y)

	var camera_forward: Vector3 = -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	var camera_right: Vector3 = camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	if camera_forward.length_squared() <= 0.0 or camera_right.length_squared() <= 0.0:
		return Vector3(input_vector.x, 0.0, input_vector.y)

	return camera_right * input_vector.x + camera_forward * -input_vector.y
