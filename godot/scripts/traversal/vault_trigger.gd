extends Area3D
class_name VaultTrigger

enum Directionality {
	ENTRY_TO_EXIT,
	EXIT_TO_ENTRY,
	BIDIRECTIONAL,
}

@export var directionality: Directionality = Directionality.ENTRY_TO_EXIT
@export var landing_collision_mask: int = 1
@export var landing_clearance_radius: float = 0.45
@export var landing_clearance_center_height: float = 0.955
@export var landing_ray_height: float = 1.8
@export var landing_ray_depth: float = 4.0
@export var side_margin: float = 0.05
@export var duration_override: float = 0.0
@export var obstacle_height: float = 0.75
@export var arc_clearance: float = 0.35
@export var player_contact_buffer: float = 0.45
@export var activation_overlap_tolerance: float = 0.55
@export var entry_face_anchor_path: NodePath
@export var exit_face_anchor_path: NodePath
@export var entry_landing_anchor_path: NodePath
@export var exit_landing_anchor_path: NodePath


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_candidate(
	player: CharacterBody3D,
	movement_direction: Vector3,
	min_alignment_dot: float,
	max_activation_distance: float,
	same_floor_tolerance: float
) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}

	if not player.is_on_floor():
		return {}

	var traversal: Dictionary = _resolve_traversal(player.global_position)
	if traversal.is_empty():
		return {}

	var source_face_anchor: Marker3D = traversal["source_face"]
	var destination_landing_anchor: Marker3D = traversal["destination_landing"]
	var travel_direction: Vector3 = traversal["travel_direction"]

	var to_source_face: Vector3 = source_face_anchor.global_position - player.global_position
	to_source_face.y = 0.0

	if movement_direction.dot(travel_direction) < min_alignment_dot:
		return {}

	var center_to_face_distance: float = to_source_face.dot(travel_direction)
	var face_distance: float = center_to_face_distance - player_contact_buffer
	if face_distance < -activation_overlap_tolerance or face_distance > max_activation_distance:
		return {}

	var lateral_offset: Vector3 = to_source_face - travel_direction * center_to_face_distance
	var clamped_face_distance: float = clampf(face_distance, 0.0, max_activation_distance)
	var score_distance_sq: float = clamped_face_distance * clamped_face_distance + lateral_offset.length_squared()

	var landing_floor: Dictionary = _resolve_landing_floor(destination_landing_anchor, player)
	if landing_floor.is_empty():
		return {}

	var floor_position: Vector3 = landing_floor["position"]
	if absf(floor_position.y - player.global_position.y) > same_floor_tolerance:
		return {}

	if not _has_landing_clearance(floor_position, player):
		return {}

	return {
		"landing_position": floor_position,
		"travel_direction": travel_direction,
		"distance_sq": score_distance_sq,
		"duration_override": duration_override,
		"arc_height": obstacle_height + arc_clearance,
	}


func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("register_vault_trigger"):
		body.register_vault_trigger(self)


func _on_body_exited(body: Node) -> void:
	if body != null and body.has_method("unregister_vault_trigger"):
		body.unregister_vault_trigger(self)


func _resolve_traversal(player_position: Vector3) -> Dictionary:
	var entry_face_anchor: Marker3D = _resolve_anchor(entry_face_anchor_path)
	var exit_face_anchor: Marker3D = _resolve_anchor(exit_face_anchor_path)
	var entry_landing_anchor: Marker3D = _resolve_anchor(entry_landing_anchor_path)
	var exit_landing_anchor: Marker3D = _resolve_anchor(exit_landing_anchor_path)
	if entry_face_anchor == null or exit_face_anchor == null or entry_landing_anchor == null or exit_landing_anchor == null:
		return {}

	var entry_to_exit: Vector3 = exit_face_anchor.global_position - entry_face_anchor.global_position
	entry_to_exit.y = 0.0
	if entry_to_exit.length_squared() <= 0.0001:
		return {}

	var forward_direction: Vector3 = entry_to_exit.normalized()
	var midpoint: Vector3 = (entry_face_anchor.global_position + exit_face_anchor.global_position) * 0.5
	var player_offset: Vector3 = player_position - midpoint
	player_offset.y = 0.0
	var side: float = player_offset.dot(forward_direction)

	match directionality:
		Directionality.EXIT_TO_ENTRY:
			if side < side_margin:
				return {}
			return {
				"source_face": exit_face_anchor,
				"destination_landing": entry_landing_anchor,
				"travel_direction": -forward_direction,
			}
		Directionality.BIDIRECTIONAL:
			if side <= -side_margin:
				return {
					"source_face": entry_face_anchor,
					"destination_landing": exit_landing_anchor,
					"travel_direction": forward_direction,
				}

			if side >= side_margin:
				return {
					"source_face": exit_face_anchor,
					"destination_landing": entry_landing_anchor,
					"travel_direction": -forward_direction,
				}

			return {}
		_:
			if side > -side_margin:
				return {}
			return {
				"source_face": entry_face_anchor,
				"destination_landing": exit_landing_anchor,
				"travel_direction": forward_direction,
			}


func _resolve_anchor(anchor_path: NodePath) -> Marker3D:
	if anchor_path.is_empty():
		return null

	return get_node_or_null(anchor_path) as Marker3D


func _resolve_landing_floor(landing_anchor: Marker3D, player: CharacterBody3D) -> Dictionary:
	var ray_origin: Vector3 = landing_anchor.global_position + Vector3.UP * landing_ray_height
	var ray_end: Vector3 = landing_anchor.global_position + Vector3.DOWN * landing_ray_depth
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, landing_collision_mask, [get_rid(), player.get_rid()])
	query.collide_with_areas = false
	query.hit_back_faces = true

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return {}

	var surface_normal: Vector3 = result.get("normal", Vector3.UP)
	if surface_normal.dot(Vector3.UP) < 0.5:
		return {}

	return result


func _has_landing_clearance(landing_position: Vector3, player: CharacterBody3D) -> bool:
	var clearance_shape := SphereShape3D.new()
	clearance_shape.radius = landing_clearance_radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = clearance_shape
	query.transform = Transform3D(Basis.IDENTITY, landing_position + Vector3.UP * landing_clearance_center_height)
	query.collision_mask = landing_collision_mask
	query.exclude = [get_rid(), player.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results: Array = get_world_3d().direct_space_state.intersect_shape(query, 8)
	return results.is_empty()
