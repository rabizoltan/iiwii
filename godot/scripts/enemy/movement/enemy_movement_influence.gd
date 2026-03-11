extends RefCounted

const EnemyRuntimeState = preload("res://scripts/enemy/state/enemy_runtime_state.gd")


class QueuePushRequest:
	extends RefCounted

	var state: EnemyRuntimeState.MovementInfluenceState
	var push_direction: Vector3 = Vector3.ZERO
	var source_position: Vector3 = Vector3.ZERO
	var global_position: Vector3 = Vector3.ZERO
	var push_speed: float = 0.0
	var max_speed: float = 0.0
	var resolve_direction: Callable


class InfluenceVelocityRequest:
	extends RefCounted

	var state: EnemyRuntimeState.MovementInfluenceState
	var base_velocity: Vector3 = Vector3.ZERO
	var move_speed: float = 0.0
	var max_speed: float = 0.0
	var decay: float = 0.0
	var delta: float = 0.0


class InfluenceVelocityResult:
	extends RefCounted

	var applied: bool = false
	var velocity: Vector3 = Vector3.ZERO
	var state: EnemyRuntimeState.MovementInfluenceState


static func queue_player_push(request: QueuePushRequest) -> EnemyRuntimeState.MovementInfluenceState:
	var push_direction: Vector3 = request.push_direction
	push_direction.y = 0.0
	if push_direction.length_squared() <= 0.0001:
		return request.state

	push_direction = push_direction.normalized()
	var source_position: Vector3 = request.source_position
	var global_position: Vector3 = request.global_position
	var away_direction: Vector3 = global_position - source_position
	away_direction.y = 0.0
	if away_direction.length_squared() > 0.0001:
		away_direction = away_direction.normalized()
	else:
		away_direction = push_direction

	var desired_direction: Vector3 = request.resolve_direction.call(away_direction, push_direction)
	if desired_direction.length_squared() <= 0.0001:
		return request.state

	var capped_speed: float = clampf(request.push_speed, 0.0, request.max_speed)
	if capped_speed <= 0.0:
		return request.state

	var state: EnemyRuntimeState.MovementInfluenceState = request.state
	var current_velocity: Vector3 = state.velocity
	var current_speed: float = current_velocity.length()
	state.velocity = desired_direction * maxf(current_speed, capped_speed)
	state.kind = "player_push"
	return state


static func apply_influence_velocity(request: InfluenceVelocityRequest) -> InfluenceVelocityResult:
	var state: EnemyRuntimeState.MovementInfluenceState = request.state
	var influence_velocity: Vector3 = state.velocity
	influence_velocity.y = 0.0
	if influence_velocity.length_squared() <= 0.0001:
		var empty_result: InfluenceVelocityResult = InfluenceVelocityResult.new()
		empty_result.velocity = request.base_velocity
		empty_result.state = EnemyRuntimeState.MovementInfluenceState.new()
		return empty_result

	var base_velocity: Vector3 = request.base_velocity
	var combined_velocity: Vector3 = base_velocity + influence_velocity
	var combined_speed: float = combined_velocity.length()
	var speed_cap: float = maxf(request.move_speed, request.max_speed)
	if combined_speed > speed_cap and combined_speed > 0.0:
		combined_velocity = combined_velocity / combined_speed * speed_cap

	state.velocity = influence_velocity.move_toward(
		Vector3.ZERO,
		request.decay * request.delta
	)
	var result: InfluenceVelocityResult = InfluenceVelocityResult.new()
	result.applied = true
	result.velocity = combined_velocity
	result.state = state
	return result
