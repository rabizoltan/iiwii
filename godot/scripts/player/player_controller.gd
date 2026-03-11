extends CharacterBody3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 10.0
@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 0.5
@export var aim_collision_mask: int = 3
@export var aim_ray_length: float = 1000.0
@export var enemy_push_speed: float = 4.5
@export var enemy_push_query_radius: float = 1.35
@export var enemy_push_query_forward_offset: float = 1.1
@export var enemy_push_query_max_results: int = 12
@export var enemy_push_query_min_forward_dot: float = 0.2
@export var enemy_crowd_assist_speed: float = 2.8
@export var enemy_crowd_assist_max_step: float = 0.09
@export var enemy_crowd_assist_enemy_layer_mask: int = 2
@export var crowd_push_debug_enabled: bool = true

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_cooldown_remaining: float = 0.0
var _enemy_push_query_shape: SphereShape3D
var _collision_shape_node: CollisionShape3D
var _last_crowd_push_log_msec: int = 0
var _debug_push_input_direction: Vector3 = Vector3.ZERO
var _debug_push_intended_speed: float = 0.0
var _debug_push_displacement: float = 0.0
var _debug_push_direct_collision_count: int = 0
var _debug_push_direct_colliders: Array[String] = []
var _debug_push_query_hit_count: int = 0
var _debug_push_query_applied_count: int = 0
var _debug_push_query_targets: Array[String] = []
var _debug_push_query_center: Vector3 = Vector3.ZERO
var _debug_push_query_best_factor: float = 0.0
var _debug_push_assist_used: bool = false
var _debug_push_assist_distance: float = 0.0
var _debug_push_assist_blocked_by_world: bool = false

const CROWD_PUSH_DEBUG_PATH := "user://debug/player_crowd_push_debug.txt"
const CROWD_PUSH_DEBUG_INTERVAL_MSEC := 100
const CROWD_PUSH_BLOCKED_DISPLACEMENT_THRESHOLD := 0.03


func _ready() -> void:
	_enemy_push_query_shape = SphereShape3D.new()
	_enemy_push_query_shape.radius = enemy_push_query_radius
	_collision_shape_node = $CollisionShape3D as CollisionShape3D
	_prepare_crowd_push_debug_log()


func _physics_process(delta: float) -> void:
	var pre_move_position := global_position
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	_reset_crowd_push_debug()

	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * move_speed
		velocity.x = target_velocity.x
		velocity.z = target_velocity.z
		_debug_push_input_direction = move_direction
		_debug_push_intended_speed = target_velocity.length()

		var target_yaw := atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_push_collided_enemies()
	if move_direction.length_squared() > 0.0:
		_push_nearby_enemies(move_direction)
		_apply_enemy_crowd_assist(move_direction, delta, pre_move_position)
	_capture_crowd_push_runtime_debug(pre_move_position)

	if _attack_cooldown_remaining > 0.0:
		_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	if Input.is_action_just_pressed("attack"):
		_try_attack()


func _try_attack() -> void:
	if projectile_scene == null or _attack_cooldown_remaining > 0.0:
		return

	var aim_target := _resolve_aim_target()
	if aim_target.is_empty():
		return

	var spawn_marker := $ProjectileSpawn as Marker3D
	var target_position: Vector3 = aim_target["position"]
	var shot_direction := target_position - spawn_marker.global_position
	if shot_direction.length_squared() <= 0.0:
		return

	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return

	var projectile_parent := get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene

	projectile_parent.add_child(projectile)

	if projectile is Node3D:
		projectile.global_position = spawn_marker.global_position

	if projectile.has_method("initialize"):
		projectile.initialize(shot_direction, target_position, get_rid())

	_attack_cooldown_remaining = attack_cooldown


func _push_collided_enemies() -> void:
	var push_direction := Vector3(velocity.x, 0.0, velocity.z)
	if push_direction.length_squared() <= 0.0001:
		return

	push_direction = push_direction.normalized()
	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue

		_debug_push_direct_collision_count += 1
		var collider := collision.get_collider()
		if collider == null:
			continue

		if collider is Node:
			_debug_push_direct_colliders.append((collider as Node).name)
		else:
			_debug_push_direct_colliders.append(str(collider))

		if collider.has_method("apply_player_collision_push"):
			collider.apply_player_collision_push(push_direction, global_position, enemy_push_speed)


func _push_nearby_enemies(move_direction: Vector3) -> void:
	if _enemy_push_query_shape == null:
		return

	if enemy_push_query_radius <= 0.0 or enemy_push_query_forward_offset < 0.0:
		return

	var horizontal_direction := move_direction
	horizontal_direction.y = 0.0
	if horizontal_direction.length_squared() <= 0.0001:
		return

	horizontal_direction = horizontal_direction.normalized()
	_enemy_push_query_shape.radius = enemy_push_query_radius

	var query_center := global_position + horizontal_direction * enemy_push_query_forward_offset
	_debug_push_query_center = query_center
	var query_transform := Transform3D(Basis.IDENTITY, query_center)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _enemy_push_query_shape
	query.transform = query_transform
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results := get_world_3d().direct_space_state.intersect_shape(query, enemy_push_query_max_results)
	_debug_push_query_hit_count = results.size()
	for result in results:
		if not result.has("collider"):
			continue

		var collider: Object = result["collider"] as Object
		if collider == null or not collider.has_method("apply_player_collision_push"):
			continue

		if collider == self:
			continue

		if not (collider is Node3D):
			continue

		var collider_node := collider as Node3D
		var to_collider := collider_node.global_position - global_position
		to_collider.y = 0.0
		var distance := to_collider.length()
		var direction_to_collider := horizontal_direction if distance <= 0.0001 else to_collider / distance
		var forward_dot := horizontal_direction.dot(direction_to_collider)
		if forward_dot < enemy_push_query_min_forward_dot:
			continue

		var distance_factor := 1.0 - clampf(distance / maxf(enemy_push_query_radius + enemy_push_query_forward_offset, 0.001), 0.0, 1.0)
		var push_factor := clampf(distance_factor * inverse_lerp(enemy_push_query_min_forward_dot, 1.0, forward_dot), 0.0, 1.0)
		if push_factor <= 0.0:
			continue

		_debug_push_query_applied_count += 1
		_debug_push_query_best_factor = maxf(_debug_push_query_best_factor, push_factor)
		_debug_push_query_targets.append("%s:%.2f" % [collider_node.name, push_factor])
		collider.apply_player_collision_push(horizontal_direction, global_position, enemy_push_speed * push_factor)


func _capture_crowd_push_runtime_debug(pre_move_position: Vector3) -> void:
	var displacement := global_position - pre_move_position
	displacement.y = 0.0
	_debug_push_displacement = displacement.length()
	_maybe_append_crowd_push_debug_log()


func _apply_enemy_crowd_assist(move_direction: Vector3, delta: float, pre_move_position: Vector3) -> void:
	if enemy_crowd_assist_speed <= 0.0 or enemy_crowd_assist_max_step <= 0.0:
		return

	var displacement := global_position - pre_move_position
	displacement.y = 0.0
	if displacement.length() > CROWD_PUSH_BLOCKED_DISPLACEMENT_THRESHOLD:
		return
	if _debug_push_query_applied_count <= 0 and _debug_push_direct_collision_count <= 0:
		return

	var horizontal_direction := move_direction
	horizontal_direction.y = 0.0
	if horizontal_direction.length_squared() <= 0.0001:
		return

	horizontal_direction = horizontal_direction.normalized()
	var pressure_factor := maxf(_debug_push_query_best_factor, 0.35)
	var assist_distance := minf(enemy_crowd_assist_speed * pressure_factor * delta, enemy_crowd_assist_max_step)
	if assist_distance <= 0.0001:
		return

	var assist_motion := horizontal_direction * assist_distance
	if _is_enemy_crowd_assist_blocked_by_world(assist_motion):
		_debug_push_assist_blocked_by_world = true
		return

	global_position += assist_motion
	_debug_push_assist_used = true
	_debug_push_assist_distance = assist_distance


func _is_enemy_crowd_assist_blocked_by_world(assist_motion: Vector3) -> bool:
	if _collision_shape_node == null or _collision_shape_node.shape == null:
		return false

	var world_mask := collision_mask & ~enemy_crowd_assist_enemy_layer_mask
	if world_mask == 0:
		return false

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_shape_node.shape
	query.transform = global_transform.translated(assist_motion)
	query.collision_mask = world_mask
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results := get_world_3d().direct_space_state.intersect_shape(query, 1)
	return not results.is_empty()


func _prepare_crowd_push_debug_log() -> void:
	if not crowd_push_debug_enabled:
		return

	DirAccess.make_dir_recursive_absolute("user://debug")
	var file := FileAccess.open(CROWD_PUSH_DEBUG_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_line("--- player crowd push debug session start ---")
	file.flush()
	_last_crowd_push_log_msec = Time.get_ticks_msec()


func _maybe_append_crowd_push_debug_log() -> void:
	if not crowd_push_debug_enabled:
		return

	if _debug_push_input_direction.length_squared() <= 0.0001:
		return

	var blocked := _debug_push_intended_speed > 0.0 and _debug_push_displacement <= CROWD_PUSH_BLOCKED_DISPLACEMENT_THRESHOLD
	var has_pressure := _debug_push_direct_collision_count > 0 or _debug_push_query_applied_count > 0
	if not blocked and not has_pressure:
		return

	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_crowd_push_log_msec < CROWD_PUSH_DEBUG_INTERVAL_MSEC:
		return

	_last_crowd_push_log_msec = now_msec
	var file := FileAccess.open(CROWD_PUSH_DEBUG_PATH, FileAccess.READ_WRITE)
	if file == null:
		return

	file.seek_end()
	file.store_line(
		"%s | pos=(%.2f, %.2f, %.2f) | input=(%.2f, %.2f) | intended=%.2f | disp=%.4f | blocked=%s | direct_collisions=%d | direct=%s | query_hits=%d | query_applied=%d | best_push=%.2f | assist=%s | assist_dist=%.4f | assist_world_blocked=%s | query_center=(%.2f, %.2f) | targets=%s" % [
			Time.get_datetime_string_from_system(),
			global_position.x,
			global_position.y,
			global_position.z,
			_debug_push_input_direction.x,
			_debug_push_input_direction.z,
			_debug_push_intended_speed,
			_debug_push_displacement,
			str(blocked),
			_debug_push_direct_collision_count,
			",".join(_debug_push_direct_colliders),
			_debug_push_query_hit_count,
			_debug_push_query_applied_count,
			_debug_push_query_best_factor,
			str(_debug_push_assist_used),
			_debug_push_assist_distance,
			str(_debug_push_assist_blocked_by_world),
			_debug_push_query_center.x,
			_debug_push_query_center.z,
			",".join(_debug_push_query_targets),
		]
	)
	file.flush()


func _reset_crowd_push_debug() -> void:
	_debug_push_input_direction = Vector3.ZERO
	_debug_push_intended_speed = 0.0
	_debug_push_displacement = 0.0
	_debug_push_direct_collision_count = 0
	_debug_push_direct_colliders.clear()
	_debug_push_query_hit_count = 0
	_debug_push_query_applied_count = 0
	_debug_push_query_targets.clear()
	_debug_push_query_center = Vector3.ZERO
	_debug_push_query_best_factor = 0.0
	_debug_push_assist_used = false
	_debug_push_assist_distance = 0.0
	_debug_push_assist_blocked_by_world = false


func _resolve_aim_target() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {}

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_position) * aim_ray_length

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, aim_collision_mask, [get_rid()])
	query.collide_with_areas = false
	query.hit_back_faces = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)
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
