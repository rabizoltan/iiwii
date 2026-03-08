extends CharacterBody3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 10.0
@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 0.2

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug_overlay"):
		_toggle_enemy_debug()

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

	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return

	var spawn_marker := $ProjectileSpawn as Marker3D
	var projectile_parent := get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene

	projectile_parent.add_child(projectile)

	if projectile is Node3D:
		projectile.global_position = spawn_marker.global_position

	var forward_direction := global_transform.basis.z
	if projectile.has_method("initialize"):
		projectile.initialize(forward_direction)

	_attack_cooldown_remaining = attack_cooldown


func _toggle_enemy_debug() -> void:
	get_tree().call_group("enemy", "toggle_debug_enabled")
