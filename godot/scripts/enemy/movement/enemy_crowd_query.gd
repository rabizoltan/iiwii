extends RefCounted


class LocalEnemyCacheState:
	extends RefCounted

	var positions: Array[Vector3] = []
	var radius: float = 0.0
	var remaining: float = 0.0


static var _enemy_registry: Array[Node3D] = []
static var _profile_cache_hits: int = 0
static var _profile_cache_misses: int = 0
static var _profile_local_query_calls: int = 0
static var _profile_nearby_query_calls: int = 0


static func register_enemy(enemy: Node3D) -> void:
	if enemy == null or _enemy_registry.has(enemy):
		return

	_enemy_registry.append(enemy)


static func unregister_enemy(enemy: Node3D) -> void:
	_enemy_registry.erase(enemy)


static func get_registered_enemy_count() -> int:
	return _enemy_registry.size()


static func reset_profile_counters() -> void:
	_profile_cache_hits = 0
	_profile_cache_misses = 0
	_profile_local_query_calls = 0
	_profile_nearby_query_calls = 0


static func get_profile_counters() -> Dictionary:
	return {
		"crowd_cache_hits": _profile_cache_hits,
		"crowd_cache_misses": _profile_cache_misses,
		"crowd_local_queries": _profile_local_query_calls,
		"crowd_nearby_queries": _profile_nearby_query_calls,
	}


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
		_profile_cache_hits += 1
		return state.positions

	_profile_cache_misses += 1
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
	_profile_local_query_calls += 1
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
	_profile_nearby_query_calls += 1
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


static func _is_valid_other_enemy(enemy: Node3D, owner: Node3D) -> bool:
	return enemy != null and enemy != owner and is_instance_valid(enemy)
