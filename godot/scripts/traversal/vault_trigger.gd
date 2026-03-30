extends Area3D
class_name VaultTrigger

enum Directionality {
	ENTRY_TO_EXIT,
	EXIT_TO_ENTRY,
	BIDIRECTIONAL,
}

enum TraversalModel {
	FIXED_ENDPOINT,
	STRIP_OFFSET,
}

@export var directionality: Directionality = Directionality.ENTRY_TO_EXIT
@export var traversal_model: TraversalModel = TraversalModel.FIXED_ENDPOINT
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
@export var strip_end_margin: float = 0.35
@export var entry_face_anchor_path: NodePath
@export var exit_face_anchor_path: NodePath
@export var entry_landing_anchor_path: NodePath
@export var exit_landing_anchor_path: NodePath

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


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

	var source_face_position: Vector3 = traversal["source_face_position"]
	var destination_landing_position: Vector3 = traversal["destination_landing_position"]
	var travel_direction: Vector3 = traversal["travel_direction"]

	var to_source_face: Vector3 = source_face_position - player.global_position
	to_source_face.y = 0.0

	if movement_direction.dot(travel_direction) < min_alignment_dot:
		return {}

	var center_to_edge_distance: float = to_source_face.dot(travel_direction)
	var edge_distance: float = center_to_edge_distance - player_contact_buffer
	if edge_distance < -activation_overlap_tolerance or edge_distance > max_activation_distance:
		return {}

	var lateral_offset: Vector3 = to_source_face - travel_direction * center_to_edge_distance
	var clamped_edge_distance: float = clampf(edge_distance, 0.0, max_activation_distance)
	var score_distance_sq: float = clamped_edge_distance * clamped_edge_distance + lateral_offset.length_squared()

	var landing_floor: Dictionary = _resolve_landing_floor(destination_landing_position, player)
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

	var source_face_anchor: Marker3D = null
	var destination_landing_anchor: Marker3D = null
	var travel_direction: Vector3 = Vector3.ZERO

	match directionality:
		Directionality.EXIT_TO_ENTRY:
			if side < side_margin:
				return {}
			source_face_anchor = exit_face_anchor
			destination_landing_anchor = entry_landing_anchor
			travel_direction = -forward_direction
		Directionality.BIDIRECTIONAL:
			if side <= -side_margin:
				source_face_anchor = entry_face_anchor
				destination_landing_anchor = exit_landing_anchor
				travel_direction = forward_direction
			elif side >= side_margin:
				source_face_anchor = exit_face_anchor
				destination_landing_anchor = entry_landing_anchor
				travel_direction = -forward_direction
			else:
				return {}
		_:
			if side > -side_margin:
				return {}
			source_face_anchor = entry_face_anchor
			destination_landing_anchor = exit_landing_anchor
			travel_direction = forward_direction

	if traversal_model == TraversalModel.STRIP_OFFSET:
		var strip_positions: Dictionary = _resolve_strip_positions(player_position, source_face_anchor.global_position, destination_landing_anchor.global_position, travel_direction)
		if strip_positions.is_empty():
			return {}

		return {
			"source_face_position": strip_positions["source_face_position"],
			"destination_landing_position": strip_positions["destination_landing_position"],
			"travel_direction": strip_positions["travel_direction"],
		}

	return {
		"source_face_position": source_face_anchor.global_position,
		"destination_landing_position": destination_landing_anchor.global_position,
		"travel_direction": travel_direction,
	}


func _resolve_strip_positions(
	player_position: Vector3,
	source_face_position: Vector3,
	destination_landing_position: Vector3,
	travel_direction: Vector3
) -> Dictionary:
	if _collision_shape == null:
		return {}

	var box_shape: BoxShape3D = _collision_shape.shape as BoxShape3D
	if box_shape == null:
		return {}
	var x_axis: Vector3 = _collision_shape.global_transform.basis.x
	x_axis.y = 0.0
	var z_axis: Vector3 = _collision_shape.global_transform.basis.z
	z_axis.y = 0.0
	var x_length: float = x_axis.length()
	var z_length: float = z_axis.length()
	if x_length <= 0.0001 or z_length <= 0.0001:
		return {}

	x_axis = x_axis / x_length
	z_axis = z_axis / z_length
	var x_dot: float = absf(x_axis.dot(travel_direction))
	var z_dot: float = absf(z_axis.dot(travel_direction))

	var along_axis: Vector3 = z_axis
	var along_half_extent: float = box_shape.size.z * 0.5 * z_length
	if x_dot < z_dot:
		along_axis = x_axis
		along_half_extent = box_shape.size.x * 0.5 * x_length

	var usable_half_extent: float = maxf(along_half_extent - strip_end_margin, 0.0)
	var to_player: Vector3 = player_position - _collision_shape.global_position
	to_player.y = 0.0
	var along_offset: float = to_player.dot(along_axis)
	if absf(along_offset) > usable_half_extent:
		return {}

	var projected_source: Vector3 = source_face_position + along_axis * along_offset
	var projected_destination: Vector3 = destination_landing_position + along_axis * along_offset
	var projected_travel: Vector3 = projected_destination - projected_source
	projected_travel.y = 0.0
	if projected_travel.length_squared() <= 0.0001:
		return {}

	return {
		"source_face_position": projected_source,
		"destination_landing_position": projected_destination,
		"travel_direction": projected_travel.normalized(),
	}


func _resolve_anchor(anchor_path: NodePath) -> Marker3D:
	if anchor_path.is_empty():
		return null

	return get_node_or_null(anchor_path) as Marker3D


func _resolve_landing_floor(landing_position: Vector3, player: CharacterBody3D) -> Dictionary:
	var ray_origin: Vector3 = landing_position + Vector3.UP * landing_ray_height
	var ray_end: Vector3 = landing_position + Vector3.DOWN * landing_ray_depth
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
