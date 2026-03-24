extends RefCounted


class LocalEnemyCacheState:
	extends RefCounted

	var positions: Array[Vector3] = []
	var radius: float = 0.0
	var remaining: float = 0.0


static var _enemy_registry: Array[Node3D] = []


static func register_enemy(enemy: Node3D) -> void:
	if enemy == null or _enemy_registry.has(enemy):
		return

	_enemy_registry.append(enemy)


static func unregister_enemy(enemy: Node3D) -> void:
	_enemy_registry.erase(enemy)


static func get_registered_enemy_count() -> int:
	return _enemy_registry.size()


static func tick_local_cache(state: LocalEnemyCacheState, delta: float) -> void:
	if state == null or state.remaining <= 0.0:
		return

	state.remaining = maxf(state.remaining - delta, 0.0)


static func get_cached_local_enemy_positions(
	owner: Node3D,
	owner_position: Vector3,
	radius: float,
	cache_interval: float,
	state: LocalEnemyCacheState
) -> Array[Vector3]:
	if radius <= 0.0:
		return []

	if state != null and state.remaining > 0.0 and state.radius >= radius:
		return state.positions

	var positions: Array[Vector3] = collect_local_enemy_positions(owner, owner_position, radius)
	if state != null:
		state.positions = positions
		state.radius = radius
		state.remaining = maxf(cache_interval, 0.0)

	return positions


static func collect_local_enemy_positions(
	owner: Node3D,
	owner_position: Vector3,
	radius: float
) -> Array[Vector3]:
	var local_positions: Array[Vector3] = []
	if radius <= 0.0:
		return local_positions

	var radius_sq := radius * radius
	for enemy in _enemy_registry:
		if not _is_valid_other_enemy(enemy, owner):
			continue

		var offset: Vector3 = enemy.global_position - owner_position
		offset.y = 0.0
		if offset.length_squared() > radius_sq:
			continue

		local_positions.append(enemy.global_position)

	return local_positions


static func collect_nearby_enemy_positions(
	owner: Node3D,
	center: Vector3,
	relevant_radius: float
) -> Array[Vector3]:
	var nearby_positions: Array[Vector3] = []
	if relevant_radius <= 0.0:
		return nearby_positions

	var relevant_radius_sq := relevant_radius * relevant_radius
	for enemy in _enemy_registry:
		if not _is_valid_other_enemy(enemy, owner):
			continue

		var offset: Vector3 = enemy.global_position - center
		offset.y = 0.0
		if offset.length_squared() > relevant_radius_sq:
			continue

		nearby_positions.append(enemy.global_position)

	return nearby_positions


static func get_target_distance_rank(
	owner: Node3D,
	owner_position: Vector3,
	target_position: Vector3,
	relevant_radius: float
) -> int:
	if relevant_radius <= 0.0:
		return 0

	var owner_distance: float = _horizontal_distance(owner_position, target_position)
	if owner_distance > relevant_radius:
		return 0

	var rank: int = 0
	var owner_instance_id: int = owner.get_instance_id() if owner != null else 0
	for enemy in _enemy_registry:
		if not _is_valid_other_enemy(enemy, owner):
			continue

		var enemy_distance: float = _horizontal_distance(enemy.global_position, target_position)
		if enemy_distance > relevant_radius:
			continue

		if enemy_distance < owner_distance - 0.001:
			rank += 1
			continue

		if absf(enemy_distance - owner_distance) <= 0.001 and enemy.get_instance_id() < owner_instance_id:
			rank += 1

	return rank


static func _is_valid_other_enemy(enemy: Node3D, owner: Node3D) -> bool:
	return enemy != null and enemy != owner and is_instance_valid(enemy)


static func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset: Vector3 = to_position - from_position
	offset.y = 0.0
	return offset.length()
