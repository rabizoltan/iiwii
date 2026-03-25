extends CharacterBody3D

const EnemyCloseState = preload("res://scripts/enemy/movement/enemy_close_state.gd")
const EnemyMovementStateMachine = preload("res://scripts/enemy/movement/enemy_movement_state_machine.gd")
const EnemyGoalSelector = preload("res://scripts/enemy/movement/enemy_goal_selector.gd")
const EnemyCrowdResponse = preload("res://scripts/enemy/movement/enemy_crowd_response.gd")
const EnemyCrowdQuery = preload("res://scripts/enemy/movement/enemy_crowd_query.gd")
const EnemyRuntimePolicy = preload("res://scripts/enemy/movement/enemy_runtime_policy.gd")
const EnemyNavigationLocomotion = preload("res://scripts/enemy/movement/enemy_navigation_locomotion.gd")
const EnemyMovementInfluence = preload("res://scripts/enemy/movement/enemy_movement_influence.gd")
const EnemyRuntimeState = preload("res://scripts/enemy/state/enemy_runtime_state.gd")


class PhysicsStepResult:
	extends RefCounted


	var attempted_horizontal_move: bool = false
	var nav_not_ready: bool = false


# Movement and targeting
@export var move_speed: float = 4.5
@export var turn_speed: float = 8.0
@export var target_path: NodePath
@export var walkable_floor_max_angle_degrees: float = 55.0
@export var walkable_floor_snap_length: float = 0.35

# Health
@export var max_hp: float = 3.0

# Melee engage behavior
@export var melee_engage_distance: float = 1.8
@export var engage_hold_tolerance: float = 0.35
@export var engage_vertical_tolerance: float = 1.0
@export var close_adjust_enter_distance: float = 2.6
@export var close_adjust_move_speed: float = 2.8
@export var close_adjust_neighbor_radius: float = 1.5
@export var close_adjust_probe_distance: float = 0.9
@export var close_adjust_min_lateral_weight: float = 0.2
@export var close_adjust_max_lateral_weight: float = 1.15
@export var close_adjust_stop_distance: float = 0.18
@export var close_adjust_gap_stop_distance: float = 0.12
@export var close_adjust_side_commit_duration: float = 0.3
@export var close_adjust_side_switch_penalty_margin: float = 0.12
@export var close_adjust_nav_refresh_interval: float = 0.12
@export var max_active_melee_enemies: int = 4
@export var melee_frontline_contender_radius: float = 3.0
@export var melee_frontline_release_buffer: int = 1

# Player-vs-crowd pressure response
@export var crowd_pressure_yield_distance: float = 1.2
@export var crowd_pressure_yield_speed: float = 4.2
@export var crowd_pressure_side_yield_weight: float = 1.0
@export var crowd_pressure_block_check_distance: float = 0.8
@export var crowd_pressure_block_neighbor_radius: float = 1.8
@export var crowd_pressure_min_yield_factor: float = 0.6
@export var external_displacement_decay: float = 10.0
@export var external_displacement_max_speed: float = 4.8
@export var external_displacement_lateral_weight: float = 1.2
@export var external_displacement_outward_weight: float = 0.35
@export var crowd_chain_yield_distance: float = 2.2
@export var crowd_chain_neighbor_radius: float = 1.1
@export var crowd_chain_yield_bonus: float = 1.1
@export var local_enemy_cache_interval: float = 0.12

# Goal selection
@export var goal_commit_duration: float = 0.6
@export var goal_select_min_interval: float = 0.2
@export var goal_select_start_jitter: float = 0.2
@export var goal_reacquire_distance: float = 0.9
@export var engage_candidate_count: int = 10
@export var goal_path_tiebreak_candidate_count: int = 3
@export var goal_path_tiebreak_score_window: float = 0.75
@export var goal_path_tiebreak_max_target_distance: float = 8.0
@export var goal_path_tiebreak_enemy_count_soft_limit: int = 24
@export var goal_path_endpoint_tolerance: float = 0.9
@export var surround_goal_activation_distance: float = 3.0
@export var spread_penalty_radius: float = 1.2
@export var spread_penalty_weight: float = 0.35
@export var candidate_projection_tolerance: float = 1.0
@export var failed_goal_exclusion_radius: float = 0.75
@export var failed_goal_memory_count: int = 2
@export var nav_refresh_interval_near: float = 0.1
@export var nav_refresh_interval_far: float = 0.5
@export var nav_refresh_far_distance: float = 3.0

# Minimal stuck fallback
@export var stuck_timeout: float = 0.35
@export var stuck_recovery_duration: float = 0.3
@export var stuck_min_progress_distance: float = 0.02

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_node: Node3D
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0
var _melee_state: int = EnemyCloseState.APPROACH
var _goal_runtime_state: EnemyRuntimePolicy.GoalRuntimeState
var _crowd_query_state: EnemyCrowdQuery.LocalEnemyCacheState
var _nav_cache_state: EnemyRuntimePolicy.NavigationCacheState
var _movement_influence_state: EnemyRuntimeState.MovementInfluenceState
var _close_adjust_side_sign: float = 0.0
var _close_adjust_side_commit_remaining: float = 0.0

const INVALID_POINT := Vector3(INF, INF, INF)


# Lifecycle
func _enter_tree() -> void:
	EnemyCrowdQuery.register_enemy(self)


func _exit_tree() -> void:
	EnemyCrowdQuery.unregister_enemy(self)


func _ready() -> void:
	_current_hp = max_hp
	floor_max_angle = deg_to_rad(walkable_floor_max_angle_degrees)
	floor_snap_length = walkable_floor_snap_length
	_goal_runtime_state = EnemyRuntimePolicy.GoalRuntimeState.new()
	_goal_runtime_state.goal_select_cooldown_remaining = randf() * maxf(goal_select_start_jitter, 0.0)
	_nav_cache_state = EnemyRuntimePolicy.NavigationCacheState.new()
	_nav_cache_state.cached_nav_move_target = INVALID_POINT
	_movement_influence_state = EnemyRuntimeState.MovementInfluenceState.new()
	_crowd_query_state = EnemyCrowdQuery.LocalEnemyCacheState.new()
	_nav_agent.set_navigation_map(get_world_3d().navigation_map)
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = engage_hold_tolerance
	call_deferred("_resolve_target")


func _resolve_target() -> void:
	_target_node = null
	if not target_path.is_empty():
		_target_node = get_node_or_null(target_path) as Node3D

	if _target_node == null:
		_target_node = get_tree().get_first_node_in_group("player") as Node3D


# Main update loop
func _physics_process(delta: float) -> void:
	var pre_move_position := global_position
	_prepare_physics_step(delta)
	var step_result: PhysicsStepResult = _run_horizontal_movement_phase(delta)
	if step_result.nav_not_ready:
		_finalize_nav_not_ready()
		return

	_apply_vertical_velocity(delta)
	_finalize_physics_step(pre_move_position, delta, step_result)


func _prepare_physics_step(delta: float) -> void:
	EnemyRuntimePolicy.tick_goal_runtime(_goal_runtime_state, delta)
	EnemyCrowdQuery.tick_local_cache(_crowd_query_state, delta)
	EnemyRuntimePolicy.tick_navigation_cache(_nav_cache_state, delta)

	if _close_adjust_side_commit_remaining > 0.0:
		_close_adjust_side_commit_remaining = maxf(_close_adjust_side_commit_remaining - delta, 0.0)


func _run_horizontal_movement_phase(delta: float) -> PhysicsStepResult:
	var result: PhysicsStepResult = PhysicsStepResult.new()
	if not _has_valid_target():
		_target_node = null
		_resolve_target()

	if not _has_valid_target():
		_clear_goal_navigation_state()
		_set_horizontal_velocity(Vector3.ZERO)
		return result

	var distance_to_target: float = _horizontal_distance_to(_target_node.global_position)
	_update_melee_state(_target_node.global_position)
	if NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map()) == 0:
		_set_horizontal_velocity(Vector3.ZERO)
		result.nav_not_ready = true
		return result

	var state_result: EnemyMovementStateMachine.StateDispatchResult = _dispatch_movement_state(delta, distance_to_target)
	_apply_state_motion(state_result, delta)

	result.attempted_horizontal_move = state_result.attempted_move

	if _apply_external_displacement(delta):
		result.attempted_horizontal_move = true

	return result


func _dispatch_movement_state(delta: float, distance_to_target: float) -> EnemyMovementStateMachine.StateDispatchResult:
	if _should_refresh_goal():
		_select_engage_goal()
		_reset_goal_select_cooldown()

	var result: EnemyMovementStateMachine.StateDispatchResult
	match _melee_state:
		EnemyCloseState.APPROACH:
			result = _run_approach_state(delta, distance_to_target)
		EnemyCloseState.CLOSE_ADJUST:
			result = _run_close_adjust_state(distance_to_target)
		EnemyCloseState.MELEE_HOLD:
			result = _run_melee_hold_state()
		_:
			result = _make_state_dispatch_result(
				"unknown",
				global_position,
				false,
				Vector3.ZERO,
				_target_node.global_position
			)
	return result


func _finalize_nav_not_ready() -> void:
	move_and_slide()


func _apply_vertical_velocity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0


func _finalize_physics_step(
	pre_move_position: Vector3,
	delta: float,
	step_result: PhysicsStepResult
) -> void:
	move_and_slide()
	_update_stuck_state(delta, pre_move_position, step_result.attempted_horizontal_move)


# Goal selection
func _should_refresh_goal() -> bool:
	var request := EnemyRuntimePolicy.GoalRefreshRequest.new()
	request.has_valid_target = _has_valid_target()
	request.goal_select_cooldown_remaining = _goal_runtime_state.goal_select_cooldown_remaining
	request.has_goal = _goal_runtime_state.has_goal
	request.goal_commit_remaining = _goal_runtime_state.goal_commit_remaining
	request.goal_center_at_selection = _goal_runtime_state.goal_center_at_selection
	request.target_position = _target_node.global_position if _target_node != null else Vector3.ZERO
	request.goal_reacquire_distance = goal_reacquire_distance
	request.global_position = global_position
	request.current_goal_position = _goal_runtime_state.current_goal_position
	request.engage_hold_tolerance = engage_hold_tolerance
	return EnemyRuntimePolicy.should_refresh_goal(request)


func _select_engage_goal() -> void:
	if _target_node == null:
		_clear_goal_navigation_state()
		return

	var target_position := _target_node.global_position
	var nearby_enemy_positions := EnemyCrowdQuery.collect_nearby_enemy_positions(
		self,
		target_position,
		melee_engage_distance + spread_penalty_radius
	)
	var goal_request: EnemyGoalSelector.SelectGoalRequest = EnemyGoalSelector.SelectGoalRequest.new()
	goal_request.target_position = target_position
	goal_request.global_position = global_position
	goal_request.melee_engage_distance = melee_engage_distance
	goal_request.engage_candidate_count = engage_candidate_count
	goal_request.nearby_enemy_positions = nearby_enemy_positions
	goal_request.navigation_map = _nav_agent.get_navigation_map()
	goal_request.navigation_layers = _nav_agent.navigation_layers
	goal_request.candidate_projection_tolerance = candidate_projection_tolerance
	goal_request.recent_failed_goals = _goal_runtime_state.recent_failed_goals
	goal_request.failed_goal_exclusion_radius = failed_goal_exclusion_radius
	goal_request.spread_penalty_radius = spread_penalty_radius
	goal_request.spread_penalty_weight = spread_penalty_weight
	goal_request.goal_path_tiebreak_candidate_count = goal_path_tiebreak_candidate_count
	goal_request.goal_path_tiebreak_score_window = goal_path_tiebreak_score_window
	goal_request.goal_path_tiebreak_enemy_count_soft_limit = goal_path_tiebreak_enemy_count_soft_limit
	goal_request.goal_path_tiebreak_max_target_distance = goal_path_tiebreak_max_target_distance
	goal_request.goal_path_endpoint_tolerance = goal_path_endpoint_tolerance
	goal_request.enemy_count = EnemyCrowdQuery.get_registered_enemy_count()
	goal_request.direct_chase_distance = surround_goal_activation_distance
	goal_request.invalid_point = INVALID_POINT
	var goal_result: EnemyGoalSelector.GoalSelectionResult = EnemyGoalSelector.select_engage_goal(goal_request)

	if not goal_result.has_goal:
		_clear_goal_navigation_state()
		return

	var apply_goal_request := EnemyRuntimePolicy.ApplyGoalSelectionRequest.new()
	apply_goal_request.goal_position = goal_result.goal_position
	apply_goal_request.goal_center = goal_result.goal_center
	apply_goal_request.goal_commit_duration = goal_commit_duration
	apply_goal_request.invalid_point = INVALID_POINT
	EnemyRuntimePolicy.apply_goal_selection(_goal_runtime_state, _nav_cache_state, apply_goal_request)


func _reset_goal_select_cooldown() -> void:
	var cooldown_request := EnemyRuntimePolicy.GoalCooldownRequest.new()
	cooldown_request.goal_select_min_interval = goal_select_min_interval
	EnemyRuntimePolicy.reset_goal_select_cooldown(_goal_runtime_state, cooldown_request)


func _remember_failed_goal(goal_position: Vector3) -> void:
	var memory_request := EnemyRuntimePolicy.GoalMemoryRequest.new()
	memory_request.goal_position = goal_position
	memory_request.failed_goal_memory_count = failed_goal_memory_count
	EnemyRuntimePolicy.remember_failed_goal(_goal_runtime_state, memory_request)


# Melee state and locomotion
func _update_melee_state(target_position: Vector3) -> void:
	var request: EnemyMovementStateMachine.TransitionRequest = EnemyMovementStateMachine.TransitionRequest.new()
	request.global_position = global_position
	request.target_position = target_position
	request.close_adjust_enter_distance = close_adjust_enter_distance
	request.melee_engage_distance = melee_engage_distance
	request.engage_hold_tolerance = engage_hold_tolerance
	request.engage_vertical_tolerance = engage_vertical_tolerance
	var next_state := EnemyMovementStateMachine.compute_next_state(request)
	if next_state != EnemyCloseState.APPROACH:
		var is_in_frontline := _is_in_active_melee_frontline(target_position)
		if not is_in_frontline:
			next_state = EnemyCloseState.APPROACH

	if next_state == _melee_state:
		return

	_melee_state = next_state
	if _melee_state != EnemyCloseState.APPROACH:
		_stuck_elapsed = 0.0
		_recovery_elapsed = 0.0
	if _melee_state != EnemyCloseState.CLOSE_ADJUST:
		_close_adjust_side_sign = 0.0
		_close_adjust_side_commit_remaining = 0.0


func _is_in_active_melee_frontline(target_position: Vector3) -> bool:
	if max_active_melee_enemies <= 0:
		return true

	var contender_radius: float = maxf(
		melee_frontline_contender_radius,
		maxf(close_adjust_enter_distance, melee_engage_distance + engage_hold_tolerance)
	)
	var allowed_rank: int = max_active_melee_enemies
	if _melee_state != EnemyCloseState.APPROACH:
		allowed_rank += max(melee_frontline_release_buffer, 0)

	var distance_rank: int = EnemyCrowdQuery.get_target_distance_rank(
		self,
		global_position,
		target_position,
		contender_radius
	)
	return distance_rank < allowed_rank


func _run_approach_state(delta: float, distance_to_target: float) -> EnemyMovementStateMachine.StateDispatchResult:
	var move_target: Vector3 = _goal_runtime_state.current_goal_position if _goal_runtime_state.has_goal else _target_node.global_position
	var next_position := _get_navigation_next_position(move_target, distance_to_target)

	if _nav_agent.is_navigation_finished():
		return _make_state_dispatch_result(
			"%s:arrived" % _get_melee_state_name(),
			next_position,
			false,
			Vector3.ZERO,
			_target_node.global_position
		)

	var approach_result: EnemyNavigationLocomotion.ApproachVelocityResult = EnemyNavigationLocomotion.compute_approach_velocity(
		global_position,
		next_position,
		_recovery_elapsed,
		_recovery_sign,
		move_speed
	)
	if not approach_result.attempted_move:
		return _make_state_dispatch_result(
			"%s:%s" % [_get_melee_state_name(), approach_result.state_suffix],
			next_position,
			false,
			Vector3.ZERO,
			_target_node.global_position
		)

	if _recovery_elapsed > 0.0:
		_recovery_elapsed = maxf(_recovery_elapsed - delta, 0.0)

	var move_velocity: Vector3 = approach_result.velocity
	var move_direction: Vector3 = move_velocity.normalized()
	return _make_state_dispatch_result(
		"%s:%s" % [_get_melee_state_name(), approach_result.state_suffix],
		next_position,
		true,
		move_velocity,
		global_position + move_direction
	)


func _run_close_adjust_state(distance_to_target: float) -> EnemyMovementStateMachine.StateDispatchResult:
	var move_target := _get_close_adjust_move_target()
	var next_position := _get_navigation_next_position(move_target, distance_to_target)
	var move_velocity := _compute_close_adjust_velocity(next_position)
	if move_velocity == Vector3.ZERO:
		return _make_state_dispatch_result(
			"%s:settling" % _get_melee_state_name(),
			next_position,
			false,
			Vector3.ZERO,
			_target_node.global_position
		)

	return _make_state_dispatch_result(
		"%s:moving" % _get_melee_state_name(),
		next_position,
		true,
		move_velocity,
		_target_node.global_position
	)


func _compute_close_adjust_velocity(next_position: Vector3) -> Vector3:
	if _target_node == null:
		return Vector3.ZERO

	var request: EnemyCrowdResponse.CloseAdjustRequest = EnemyCrowdResponse.CloseAdjustRequest.new()
	request.next_position = next_position
	request.global_position = global_position
	request.target_position = _target_node.global_position
	request.distance_to_target = _horizontal_distance_to(_target_node.global_position)
	request.local_enemy_positions = _get_cached_local_enemy_positions(close_adjust_neighbor_radius)
	request.crowd_chain_neighbor_radius = crowd_chain_neighbor_radius
	request.melee_engage_distance = melee_engage_distance
	request.engage_hold_tolerance = engage_hold_tolerance
	request.close_adjust_stop_distance = close_adjust_stop_distance
	request.close_adjust_gap_stop_distance = close_adjust_gap_stop_distance
	request.close_adjust_probe_distance = close_adjust_probe_distance
	request.close_adjust_side_sign = _close_adjust_side_sign
	request.close_adjust_side_switch_penalty_margin = close_adjust_side_switch_penalty_margin
	request.close_adjust_side_commit_remaining = _close_adjust_side_commit_remaining
	request.close_adjust_side_commit_duration = close_adjust_side_commit_duration
	request.close_adjust_min_lateral_weight = close_adjust_min_lateral_weight
	request.close_adjust_max_lateral_weight = close_adjust_max_lateral_weight
	request.close_adjust_move_speed = close_adjust_move_speed
	var close_adjust_result: EnemyCrowdResponse.CloseAdjustResult = EnemyCrowdResponse.compute_close_adjust_velocity(request)
	_close_adjust_side_sign = close_adjust_result.close_adjust_side_sign
	_close_adjust_side_commit_remaining = close_adjust_result.close_adjust_side_commit_remaining
	return close_adjust_result.velocity


func _get_close_adjust_move_target() -> Vector3:
	if _target_node == null:
		return global_position

	if not _goal_runtime_state.has_goal:
		return _target_node.global_position

	var target_shift := _horizontal_distance(_goal_runtime_state.goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return _target_node.global_position

	return _goal_runtime_state.current_goal_position


func _run_melee_hold_state() -> EnemyMovementStateMachine.StateDispatchResult:
	var hold_velocity := _compute_player_yield_velocity(false)
	if hold_velocity != Vector3.ZERO:
		return _make_state_dispatch_result(
			"%s:yielding" % _get_melee_state_name(),
			global_position,
			true,
			hold_velocity,
			_target_node.global_position
		)

	_close_adjust_side_sign = 0.0
	_close_adjust_side_commit_remaining = 0.0
	return _make_state_dispatch_result(
		"%s:holding" % _get_melee_state_name(),
		global_position,
		false,
		Vector3.ZERO,
		_target_node.global_position
	)


func _get_melee_state_name() -> String:
	return EnemyCloseState.get_state_name(_melee_state)


# Crowd pressure response
func _compute_player_yield_velocity(allow_chain_pressure: bool = true) -> Vector3:
	if _target_node == null or crowd_pressure_yield_distance <= 0.0:
		return Vector3.ZERO

	var request: EnemyCrowdResponse.PlayerYieldRequest = EnemyCrowdResponse.PlayerYieldRequest.new()
	request.global_position = global_position
	request.target_position = _target_node.global_position
	request.local_enemy_positions = _get_cached_local_enemy_positions(crowd_pressure_block_neighbor_radius)
	request.crowd_pressure_yield_distance = crowd_pressure_yield_distance
	request.crowd_chain_yield_distance = crowd_chain_yield_distance
	request.crowd_chain_yield_bonus = crowd_chain_yield_bonus
	request.crowd_chain_neighbor_radius = crowd_chain_neighbor_radius
	request.crowd_pressure_side_yield_weight = crowd_pressure_side_yield_weight
	request.crowd_pressure_min_yield_factor = crowd_pressure_min_yield_factor
	request.crowd_pressure_block_check_distance = crowd_pressure_block_check_distance
	request.crowd_pressure_yield_speed = crowd_pressure_yield_speed
	request.allow_chain_pressure = allow_chain_pressure
	var yield_result: EnemyCrowdResponse.PlayerYieldResult = EnemyCrowdResponse.compute_player_yield_velocity(request)
	return yield_result.velocity


func _get_cached_local_enemy_positions(radius: float) -> Array[Vector3]:
	return EnemyCrowdQuery.get_cached_local_enemy_positions(
		self,
		global_position,
		radius,
		local_enemy_cache_interval,
		_crowd_query_state
	)


func _make_state_dispatch_result(
	state_text: String,
	next_position: Vector3,
	attempted_move: bool,
	move_velocity: Vector3,
	face_position: Vector3
) -> EnemyMovementStateMachine.StateDispatchResult:
	var result: EnemyMovementStateMachine.StateDispatchResult = EnemyMovementStateMachine.StateDispatchResult.new()
	result.state = state_text
	result.next_position = next_position
	result.attempted_move = attempted_move
	result.move_velocity = move_velocity
	result.face_position = face_position
	return result


func _apply_state_motion(state_result: EnemyMovementStateMachine.StateDispatchResult, delta: float) -> void:
	_set_horizontal_velocity(state_result.move_velocity)
	_face_position(state_result.face_position, delta)


func _set_horizontal_velocity(move_velocity: Vector3) -> void:
	velocity.x = move_velocity.x
	velocity.z = move_velocity.z


func _face_position(target_position: Vector3, delta: float) -> void:
	var face_offset := target_position - global_position
	face_offset.y = 0.0
	if face_offset.length_squared() <= 0.0001:
		return

	var target_yaw := atan2(face_offset.x, face_offset.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)


func apply_external_movement_influence(
	influence_direction: Vector3,
	source_position: Vector3,
	influence_speed: float,
	influence_kind: String = "external_displacement"
) -> void:
	match influence_kind:
		"external_displacement", "player_push":
			var request: EnemyMovementInfluence.QueuePushRequest = EnemyMovementInfluence.QueuePushRequest.new()
			request.state = _movement_influence_state
			request.push_direction = influence_direction
			request.source_position = source_position
			request.global_position = global_position
			request.push_speed = influence_speed
			request.max_speed = external_displacement_max_speed
			request.resolve_direction = func(away_direction: Vector3, push_direction: Vector3) -> Vector3:
				return _choose_external_displacement_resolution_direction(away_direction, push_direction)
			_movement_influence_state = EnemyMovementInfluence.queue_external_displacement(request)
		_:
			return


func _choose_external_displacement_resolution_direction(away_direction: Vector3, push_direction: Vector3) -> Vector3:
	var request: EnemyCrowdResponse.PushResolutionRequest = EnemyCrowdResponse.PushResolutionRequest.new()
	request.global_position = global_position
	request.away_direction = away_direction
	request.push_direction = push_direction
	request.local_enemy_positions = _get_cached_local_enemy_positions(crowd_pressure_block_neighbor_radius)
	request.block_check_distance = crowd_pressure_block_check_distance
	request.lateral_weight = external_displacement_lateral_weight
	request.outward_weight = external_displacement_outward_weight
	return EnemyCrowdResponse.choose_external_displacement_resolution_direction(request)


func _apply_external_displacement(delta: float) -> bool:
	if _movement_influence_state == null or _movement_influence_state.is_empty():
		return false

	var request: EnemyMovementInfluence.InfluenceVelocityRequest = EnemyMovementInfluence.InfluenceVelocityRequest.new()
	request.state = _movement_influence_state
	request.base_velocity = Vector3(velocity.x, 0.0, velocity.z)
	request.move_speed = move_speed
	request.max_speed = external_displacement_max_speed
	request.decay = external_displacement_decay
	request.delta = delta
	var push_result: EnemyMovementInfluence.InfluenceVelocityResult = EnemyMovementInfluence.apply_influence_velocity(request)
	_set_horizontal_velocity(push_result.velocity)
	_movement_influence_state = push_result.state
	return push_result.applied


func _update_stuck_state(delta: float, pre_move_position: Vector3, attempted_horizontal_move: bool) -> void:
	if _melee_state != EnemyCloseState.APPROACH:
		_stuck_elapsed = 0.0
		return

	if _nav_agent.is_navigation_finished() or not attempted_horizontal_move:
		_stuck_elapsed = 0.0
		return

	var horizontal_delta := global_position - pre_move_position
	horizontal_delta.y = 0.0

	if horizontal_delta.length() <= stuck_min_progress_distance:
		_stuck_elapsed += delta
	else:
		_stuck_elapsed = 0.0

	if _stuck_elapsed >= stuck_timeout:
		_stuck_elapsed = 0.0
		if _goal_runtime_state.has_goal:
			_remember_failed_goal(_goal_runtime_state.current_goal_position)
			_clear_goal_navigation_state()
		_recovery_elapsed = stuck_recovery_duration
		_recovery_sign *= -1.0


# Navigation helpers
func _get_navigation_next_position(move_target: Vector3, distance_to_target: float) -> Vector3:
	var request := EnemyRuntimePolicy.NavigationNextPositionRequest.new()
	request.cache_state = _nav_cache_state
	request.move_target = move_target
	request.invalid_point = INVALID_POINT
	request.recovery_elapsed = _recovery_elapsed
	request.melee_state = _melee_state
	request.approach_state = EnemyCloseState.APPROACH
	request.distance_to_target = distance_to_target
	request.nav_refresh_far_distance = nav_refresh_far_distance
	request.close_adjust_state = EnemyCloseState.CLOSE_ADJUST
	request.close_adjust_nav_refresh_interval = close_adjust_nav_refresh_interval
	request.nav_refresh_interval_near = nav_refresh_interval_near
	request.nav_refresh_interval_far = nav_refresh_interval_far
	request.resolve_next_position = _refresh_navigation_cache
	return EnemyRuntimePolicy.get_navigation_next_position(request)


func _clear_goal_navigation_state() -> void:
	EnemyRuntimePolicy.clear_goal_navigation_state(
		_goal_runtime_state,
		_nav_cache_state,
		_nav_agent,
		global_position,
		INVALID_POINT
	)


func _refresh_navigation_cache(move_target: Vector3) -> Vector3:
	_nav_agent.target_position = move_target
	return EnemyNavigationLocomotion.resolve_navigation_next_position(
		_nav_agent,
		global_position,
		move_target
	)


# Utility helpers
func _horizontal_distance_to(target_position: Vector3) -> float:
	return _horizontal_distance(global_position, target_position)


func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	var offset := to_position - from_position
	offset.y = 0.0
	return offset.length()


func _has_valid_target() -> bool:
	return _target_node != null and is_instance_valid(_target_node)


func apply_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	if _current_hp <= 0.0:
		queue_free()
