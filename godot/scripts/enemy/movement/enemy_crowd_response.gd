extends RefCounted


class CloseAdjustRequest:
	extends RefCounted

	var next_position: Vector3 = Vector3.ZERO
	var global_position: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	var local_enemy_positions: Array[Vector3] = []
	var distance_to_target: float = 0.0
	var melee_engage_distance: float = 0.0
	var engage_hold_tolerance: float = 0.0
	var close_adjust_stop_distance: float = 0.0
	var close_adjust_gap_stop_distance: float = 0.0
	var close_adjust_probe_distance: float = 0.0
	var close_adjust_side_sign: float = 0.0
	var close_adjust_side_switch_penalty_margin: float = 0.0
	var close_adjust_side_commit_remaining: float = 0.0
	var close_adjust_side_commit_duration: float = 0.0
	var close_adjust_min_lateral_weight: float = 0.0
	var close_adjust_max_lateral_weight: float = 0.0
	var close_adjust_move_speed: float = 0.0
	var crowd_chain_neighbor_radius: float = 0.0


class CloseAdjustResult:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var debug_path_distance: float = 0.0
	var debug_target_gap: float = 0.0
	var debug_crowd_pressure: float = 0.0
	var debug_left_penalty: float = 0.0
	var debug_right_penalty: float = 0.0
	var debug_side_sign: float = 0.0
	var debug_lateral_weight: float = 0.0
	var debug_move_speed: float = 0.0
	var close_adjust_side_sign: float = 0.0
	var close_adjust_side_commit_remaining: float = 0.0


class PlayerYieldRequest:
	extends RefCounted

	var global_position: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	var local_enemy_positions: Array[Vector3] = []
	var crowd_pressure_yield_distance: float = 0.0
	var crowd_chain_yield_distance: float = 0.0
	var crowd_chain_yield_bonus: float = 0.0
	var crowd_chain_neighbor_radius: float = 0.0
	var crowd_pressure_side_yield_weight: float = 0.0
	var crowd_pressure_min_yield_factor: float = 0.0
	var crowd_pressure_block_check_distance: float = 0.0
	var crowd_pressure_yield_speed: float = 0.0
	var allow_chain_pressure: bool = true


class PlayerYieldResult:
	extends RefCounted

	var velocity: Vector3 = Vector3.ZERO
	var debug_neighbor_count: int = 0
	var debug_crowd_pressure: float = 0.0
	var debug_direct_pressure: float = 0.0
	var debug_chain_pressure: float = 0.0
	var debug_direction: Vector3 = Vector3.ZERO
	var debug_penalty: float = 0.0
	var debug_strength: float = 0.0
	var debug_speed: float = 0.0


class PushResolutionRequest:
	extends RefCounted

	var global_position: Vector3 = Vector3.ZERO
	var away_direction: Vector3 = Vector3.ZERO
	var push_direction: Vector3 = Vector3.ZERO
	var local_enemy_positions: Array[Vector3] = []
	var block_check_distance: float = 0.0
	var lateral_weight: float = 0.0
	var outward_weight: float = 0.0


static func compute_close_adjust_velocity(request: CloseAdjustRequest) -> CloseAdjustResult:
	var next_position: Vector3 = request.next_position
	var global_position: Vector3 = request.global_position
	var target_position: Vector3 = request.target_position
	var local_enemy_positions: Array[Vector3] = request.local_enemy_positions
	var distance_to_target: float = request.distance_to_target
	var melee_engage_distance: float = request.melee_engage_distance
	var engage_hold_tolerance: float = request.engage_hold_tolerance
	var close_adjust_stop_distance: float = request.close_adjust_stop_distance
	var close_adjust_gap_stop_distance: float = request.close_adjust_gap_stop_distance
	var close_adjust_probe_distance: float = request.close_adjust_probe_distance
	var close_adjust_side_sign: float = request.close_adjust_side_sign
	var close_adjust_side_switch_penalty_margin: float = request.close_adjust_side_switch_penalty_margin
	var close_adjust_side_commit_remaining: float = request.close_adjust_side_commit_remaining
	var close_adjust_side_commit_duration: float = request.close_adjust_side_commit_duration
	var close_adjust_min_lateral_weight: float = request.close_adjust_min_lateral_weight
	var close_adjust_max_lateral_weight: float = request.close_adjust_max_lateral_weight
	var close_adjust_move_speed: float = request.close_adjust_move_speed
	var crowd_chain_neighbor_radius: float = request.crowd_chain_neighbor_radius
	var path_direction: Vector3 = next_position - global_position
	path_direction.y = 0.0
	var path_distance: float = path_direction.length()
	var result: CloseAdjustResult = CloseAdjustResult.new()
	result.debug_path_distance = path_distance
	result.close_adjust_side_sign = close_adjust_side_sign
	result.debug_side_sign = close_adjust_side_sign
	result.close_adjust_side_commit_remaining = close_adjust_side_commit_remaining
	if path_direction.length_squared() <= 0.0001:
		path_direction = target_position - global_position
		path_direction.y = 0.0

	if path_direction.length_squared() <= 0.0001:
		return result

	var move_direction: Vector3 = path_direction.normalized()
	var away_direction: Vector3 = global_position - target_position
	away_direction.y = 0.0
	if away_direction.length_squared() <= 0.0001:
		away_direction = -move_direction
	else:
		away_direction = away_direction.normalized()

	var crowd_pressure: float = compute_crowd_pressure(
		global_position,
		local_enemy_positions,
		crowd_chain_neighbor_radius
	)
	var target_gap: float = maxf(
		distance_to_target - (melee_engage_distance + engage_hold_tolerance),
		0.0
	)
	if path_distance <= close_adjust_stop_distance and target_gap <= close_adjust_gap_stop_distance:
		result.debug_target_gap = target_gap
		result.debug_crowd_pressure = crowd_pressure
		return result

	var lateral_response: Dictionary = choose_close_adjust_lateral_direction(
		global_position,
		away_direction,
		local_enemy_positions,
		close_adjust_probe_distance,
		close_adjust_side_sign,
		close_adjust_side_switch_penalty_margin,
		close_adjust_side_commit_remaining,
		close_adjust_side_commit_duration
	)
	var lateral_direction := lateral_response["direction"] as Vector3
	var lateral_weight: float = lerpf(
		close_adjust_min_lateral_weight,
		close_adjust_max_lateral_weight,
		clampf(crowd_pressure, 0.0, 1.0)
	)
	var desired_direction: Vector3 = move_direction
	if lateral_direction != Vector3.ZERO:
		desired_direction = (move_direction + lateral_direction * lateral_weight).normalized()

	if desired_direction.length_squared() <= 0.0001:
		desired_direction = Vector3.ZERO

	result.velocity = desired_direction * close_adjust_move_speed
	result.debug_target_gap = target_gap
	result.debug_crowd_pressure = crowd_pressure
	result.debug_left_penalty = float(lateral_response["left_penalty"])
	result.debug_right_penalty = float(lateral_response["right_penalty"])
	result.debug_side_sign = float(lateral_response["side_sign"])
	result.debug_lateral_weight = lateral_weight
	result.debug_move_speed = close_adjust_move_speed
	result.close_adjust_side_sign = float(lateral_response["side_sign"])
	result.close_adjust_side_commit_remaining = float(lateral_response["side_commit_remaining"])
	return result


static func compute_player_yield_velocity(request: PlayerYieldRequest) -> PlayerYieldResult:
	var global_position: Vector3 = request.global_position
	var target_position: Vector3 = request.target_position
	var local_enemy_positions: Array[Vector3] = request.local_enemy_positions
	var crowd_pressure_yield_distance: float = request.crowd_pressure_yield_distance
	var crowd_chain_yield_distance: float = request.crowd_chain_yield_distance
	var crowd_chain_yield_bonus: float = request.crowd_chain_yield_bonus
	var crowd_chain_neighbor_radius: float = request.crowd_chain_neighbor_radius
	var crowd_pressure_side_yield_weight: float = request.crowd_pressure_side_yield_weight
	var crowd_pressure_min_yield_factor: float = request.crowd_pressure_min_yield_factor
	var crowd_pressure_block_check_distance: float = request.crowd_pressure_block_check_distance
	var crowd_pressure_yield_speed: float = request.crowd_pressure_yield_speed
	var offset: Vector3 = global_position - target_position
	offset.y = 0.0
	var distance_to_target: float = offset.length()
	var away_direction: Vector3 = Vector3.FORWARD if distance_to_target <= 0.0001 else offset / distance_to_target
	var result: PlayerYieldResult = PlayerYieldResult.new()
	result.debug_neighbor_count = local_enemy_positions.size()
	var crowd_pressure: float = compute_crowd_pressure(
		global_position,
		local_enemy_positions,
		crowd_chain_neighbor_radius
	)
	result.debug_crowd_pressure = crowd_pressure
	var direct_pressure := 0.0
	if distance_to_target < crowd_pressure_yield_distance:
		direct_pressure = 1.0 - clampf(distance_to_target / crowd_pressure_yield_distance, 0.0, 1.0)
	result.debug_direct_pressure = direct_pressure

	var chain_pressure := 0.0
	var allow_chain_pressure: bool = request.allow_chain_pressure
	if allow_chain_pressure \
		and crowd_chain_yield_distance > crowd_pressure_yield_distance \
		and distance_to_target < crowd_chain_yield_distance:
		var chain_ratio := 1.0 - clampf(
			(distance_to_target - crowd_pressure_yield_distance) /
				(crowd_chain_yield_distance - crowd_pressure_yield_distance),
			0.0,
			1.0
		)
		chain_pressure = crowd_pressure * chain_ratio
	result.debug_chain_pressure = chain_pressure

	var yield_activation: float = maxf(direct_pressure, chain_pressure)
	if yield_activation <= 0.0:
		return result

	var best_response: Dictionary = choose_best_yield_response(
		global_position,
		away_direction,
		local_enemy_positions,
		crowd_pressure_side_yield_weight,
		crowd_pressure_min_yield_factor,
		crowd_pressure_block_check_distance
	)
	var best_direction := best_response["direction"] as Vector3
	if best_direction == Vector3.ZERO:
		result.debug_penalty = float(best_response["penalty"])
		return result

	var yield_strength := float(best_response["strength"])
	var boosted_strength := clampf(
		yield_strength + crowd_pressure * crowd_chain_yield_bonus,
		crowd_pressure_min_yield_factor,
		1.6
	)
	var yield_speed: float = crowd_pressure_yield_speed * yield_activation * boosted_strength
	if yield_speed <= 0.01:
		yield_speed = 0.0
		best_direction = Vector3.ZERO

	result.velocity = best_direction * yield_speed
	result.debug_direction = best_direction
	result.debug_penalty = float(best_response["penalty"])
	result.debug_strength = boosted_strength
	result.debug_speed = yield_speed
	return result


static func choose_external_displacement_resolution_direction(request: PushResolutionRequest) -> Vector3:
	var away_direction: Vector3 = request.away_direction
	var push_direction: Vector3 = request.push_direction
	var local_enemy_positions: Array[Vector3] = request.local_enemy_positions
	var left_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var right_direction := -left_direction
	var penalties := score_direction_penalties(
		request.global_position,
		[left_direction, right_direction],
		local_enemy_positions,
		request.block_check_distance
	)
	var left_penalty := penalties[0]
	var right_penalty := penalties[1]
	var lateral_direction := left_direction if left_penalty <= right_penalty else right_direction

	var outward_direction := away_direction
	if outward_direction.length_squared() <= 0.0001:
		outward_direction = push_direction

	var desired_direction := (
		lateral_direction * request.lateral_weight +
		outward_direction * request.outward_weight
	).normalized()
	if desired_direction.length_squared() > 0.0001:
		return desired_direction

	return outward_direction.normalized()


static func compute_crowd_pressure(
	global_position: Vector3,
	local_enemy_positions: Array[Vector3],
	neighbor_radius: float
) -> float:
	if neighbor_radius <= 0.0 or local_enemy_positions.is_empty():
		return 0.0

	var pressure := 0.0
	var neighbor_radius_sq := neighbor_radius * neighbor_radius
	for enemy_position in local_enemy_positions:
		var offset := enemy_position - global_position
		offset.y = 0.0
		var distance_sq := offset.length_squared()
		if distance_sq >= neighbor_radius_sq:
			continue

		var distance_to_enemy := sqrt(distance_sq)
		pressure += 1.0 - (distance_to_enemy / neighbor_radius)

	return clampf(pressure, 0.0, 1.0)


static func choose_close_adjust_lateral_direction(
	global_position: Vector3,
	away_direction: Vector3,
	local_enemy_positions: Array[Vector3],
	probe_distance: float,
	current_side_sign: float,
	side_switch_penalty_margin: float,
	side_commit_remaining: float,
	side_commit_duration: float
) -> Dictionary:
	var left_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var right_direction := -left_direction
	var penalties := score_direction_penalties(
		global_position,
		[left_direction, right_direction],
		local_enemy_positions,
		probe_distance
	)
	var left_penalty := penalties[0]
	var right_penalty := penalties[1]

	var preferred_sign := -1.0 if left_penalty <= right_penalty else 1.0
	var preferred_penalty := left_penalty if preferred_sign < 0.0 else right_penalty
	var resolved_side_sign := current_side_sign
	var current_penalty := preferred_penalty
	if resolved_side_sign < 0.0:
		current_penalty = left_penalty
	elif resolved_side_sign > 0.0:
		current_penalty = right_penalty

	if resolved_side_sign == 0.0:
		resolved_side_sign = preferred_sign
		side_commit_remaining = side_commit_duration
	elif preferred_sign != resolved_side_sign:
		var penalty_delta := current_penalty - preferred_penalty
		if side_commit_remaining <= 0.0 and penalty_delta >= side_switch_penalty_margin:
			resolved_side_sign = preferred_sign
			side_commit_remaining = side_commit_duration

	return {
		"direction": left_direction if resolved_side_sign < 0.0 else right_direction,
		"left_penalty": left_penalty,
		"right_penalty": right_penalty,
		"side_sign": resolved_side_sign,
		"side_commit_remaining": side_commit_remaining,
	}


static func choose_best_yield_response(
	global_position: Vector3,
	away_direction: Vector3,
	local_enemy_positions: Array[Vector3],
	side_yield_weight: float,
	min_yield_factor: float,
	block_check_distance: float
) -> Dictionary:
	var side_direction := Vector3(-away_direction.z, 0.0, away_direction.x)
	var candidate_directions: Array[Dictionary] = [
		{"direction": away_direction, "bias": 1.0},
		{"direction": (away_direction + side_direction * side_yield_weight).normalized(), "bias": 1.08},
		{"direction": (away_direction - side_direction * side_yield_weight).normalized(), "bias": 1.08},
	]
	var penalty_inputs: Array[Vector3] = []
	for candidate in candidate_directions:
		penalty_inputs.append(candidate["direction"])
	var penalties := score_direction_penalties(
		global_position,
		penalty_inputs,
		local_enemy_positions,
		block_check_distance
	)

	var best_direction := Vector3.ZERO
	var best_penalty := INF
	for index in range(candidate_directions.size()):
		var candidate := candidate_directions[index]
		var direction: Vector3 = candidate["direction"]
		if direction.length_squared() <= 0.0001:
			continue

		var penalty := penalties[index] * float(candidate["bias"])
		if penalty < best_penalty:
			best_penalty = penalty
			best_direction = direction

	if best_direction == Vector3.ZERO:
		return {"direction": Vector3.ZERO, "strength": 0.0, "penalty": INF}

	return {
		"direction": best_direction,
		"strength": clampf(1.0 - best_penalty, min_yield_factor, 1.0),
		"penalty": best_penalty,
	}


static func score_direction_penalty(
	global_position: Vector3,
	direction: Vector3,
	local_enemy_positions: Array[Vector3],
	probe_distance: float
) -> float:
	return score_direction_penalties(
		global_position,
		[direction],
		local_enemy_positions,
		probe_distance
	)[0]


static func score_direction_penalties(
	global_position: Vector3,
	directions: Array[Vector3],
	local_enemy_positions: Array[Vector3],
	probe_distance: float
) -> Array[float]:
	var penalties: Array[float] = []
	for _direction in directions:
		penalties.append(0.0)

	if probe_distance <= 0.0 or directions.is_empty() or local_enemy_positions.is_empty():
		return penalties

	var probe_distance_sq := probe_distance * probe_distance
	var probe_positions: Array[Vector3] = []
	var active_directions: Array[bool] = []
	for direction in directions:
		var is_active := direction.length_squared() > 0.0001
		active_directions.append(is_active)
		if is_active:
			probe_positions.append(global_position + direction * probe_distance)
		else:
			probe_positions.append(global_position)

	for enemy_position in local_enemy_positions:
		for index in range(directions.size()):
			if not active_directions[index]:
				continue

			var offset := enemy_position - probe_positions[index]
			offset.y = 0.0
			var distance_sq := offset.length_squared()
			if distance_sq >= probe_distance_sq:
				continue

			var distance_to_enemy := sqrt(distance_sq)
			penalties[index] += 1.0 - (distance_to_enemy / probe_distance)

	return penalties
