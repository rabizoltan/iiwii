extends CharacterBody3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 10.0
@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 0.5
@export var aim_collision_mask: int = 3
@export var aim_ray_length: float = 1000.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * move_speed
		velocity.x = target_velocity.x
		velocity.z = target_velocity.z

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
