extends Area3D

@export var speed: float = 18.0
@export var damage: float = 1.0
@export var hit_collision_mask: int = 3

var _direction: Vector3 = Vector3.FORWARD
var _target_position: Vector3 = Vector3.ZERO
var _source_rid: RID
var _start_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	monitoring = false
	_start_position = global_position


func initialize(direction: Vector3, target_position: Vector3, source_rid: RID) -> void:
	if direction.length_squared() <= 0.0:
		_direction = Vector3.FORWARD
	else:
		_direction = direction.normalized()

	_target_position = target_position
	_source_rid = source_rid
	_start_position = global_position


func _physics_process(delta: float) -> void:
	var remaining_to_target := _target_position - global_position
	if remaining_to_target.length_squared() <= 0.0001:
		_emit_debug_line(global_position, false)
		queue_free()
		return

	var step_distance := minf(speed * delta, remaining_to_target.length())
	var next_position := global_position + _direction * step_distance
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position, hit_collision_mask, [_source_rid])
	query.collide_with_areas = false
	query.hit_back_faces = true

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_resolve_hit(hit)
		return

	global_position = next_position

	if global_position.distance_squared_to(_target_position) <= 0.0025:
		_emit_debug_line(_target_position, false)
		queue_free()


func _resolve_hit(hit: Dictionary) -> void:
	global_position = hit["position"]
	if not hit.has("collider"):
		_emit_debug_line(global_position, false)
		queue_free()
		return

	var body: Node = hit["collider"] as Node
	if body == null:
		_emit_debug_line(global_position, false)
		queue_free()
		return

	if body.is_in_group("player"):
		return

	var applied_damage := false
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
		applied_damage = true

	_emit_debug_line(global_position, applied_damage)
	queue_free()


func _emit_debug_line(end_position: Vector3, is_hit: bool) -> void:
	var debug_overlay: Node = get_tree().get_first_node_in_group("debug_overlay")
	if debug_overlay != null and debug_overlay.has_method("spawn_projectile_debug_line"):
		debug_overlay.spawn_projectile_debug_line(_start_position, end_position, is_hit)
