extends CharacterBody3D

const EnemyCloseState = preload("res://scripts/enemy/movement/enemy_close_state.gd")
const EnemyMovementStateMachine = preload("res://scripts/enemy/movement/enemy_movement_state_machine.gd")
const EnemyGoalSelector = preload("res://scripts/enemy/movement/enemy_goal_selector.gd")
const EnemyCrowdResponse = preload("res://scripts/enemy/movement/enemy_crowd_response.gd")
const EnemyCrowdQuery = preload("res://scripts/enemy/movement/enemy_crowd_query.gd")
const EnemyRuntimePolicy = preload("res://scripts/enemy/movement/enemy_runtime_policy.gd")
const EnemyNavigationLocomotion = preload("res://scripts/enemy/movement/enemy_navigation_locomotion.gd")
const EnemyMovementInfluence = preload("res://scripts/enemy/movement/enemy_movement_influence.gd")
const EnemyDebugTelemetry = preload("res://scripts/enemy/debug/enemy_debug_telemetry.gd")
const EnemyDebugSnapshot = preload("res://scripts/enemy/debug/enemy_debug_snapshot.gd")
const EnemyDebugSnapshotBuilder = preload("res://scripts/enemy/debug/enemy_debug_snapshot_builder.gd")
const EnemyRuntimeState = preload("res://scripts/enemy/state/enemy_runtime_state.gd")


class PhysicsStepResult:
	extends RefCounted

	var debug_state: String = "idle"
	var debug_next_position: Vector3 = Vector3.ZERO
	var debug_iteration_id: int = 0
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
@export var spread_penalty_radius: float = 1.2
@export var spread_penalty_weight: float = 0.35
@export var candidate_projection_tolerance: float = 1.0
@export var failed_goal_exclusion_radius: float = 0.75
@export var failed_goal_memory_count: int = 2
@export var nav_refresh_interval_near: float = 0.0
@export var nav_refresh_interval_far: float = 0.02
@export var nav_refresh_far_distance: float = 10.0

# Minimal stuck fallback
@export var stuck_timeout: float = 0.35
@export var stuck_recovery_duration: float = 0.3
@export var stuck_min_progress_distance: float = 0.02

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _nav_path_debug: MeshInstance3D = $NavPathDebug

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_node: Node3D
var _telemetry: EnemyDebugTelemetry
var _stuck_elapsed: float = 0.0
var _recovery_elapsed: float = 0.0
var _recovery_sign: float = 1.0
var _current_hp: float = 0.0
var _melee_state: int = EnemyCloseState.APPROACH
var _melee_state_age: float = 0.0
var _melee_state_transition_count: int = 0
var _goal_runtime_state: EnemyRuntimePolicy.GoalRuntimeState
var _goal_debug_state: EnemyRuntimeState.GoalDebugState
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
	_goal_debug_state = EnemyRuntimeState.GoalDebugState.new()
	_nav_cache_state = EnemyRuntimePolicy.NavigationCacheState.new()
	_nav_cache_state.cached_nav_move_target = INVALID_POINT
	_movement_influence_state = EnemyRuntimeState.MovementInfluenceState.new()
	_crowd_query_state = EnemyCrowdQuery.LocalEnemyCacheState.new()
	_telemetry = EnemyDebugTelemetry.new()
	_telemetry.setup(self, _nav_path_debug)
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
	var physics_start_usec := Time.get_ticks_usec()
	var pre_move_position := global_position
	var prepare_start_usec := _profile_start_usec()
	_prepare_physics_step(delta)
	_record_profile_duration("prepare", Time.get_ticks_usec() - prepare_start_usec)
	var horizontal_phase_start_usec := _profile_start_usec()
	var step_result: PhysicsStepResult = _run_horizontal_movement_phase(delta)
	_record_profile_duration("horizontal_phase", Time.get_ticks_usec() - horizontal_phase_start_usec)
	if step_result.nav_not_ready:
		_finalize_nav_not_ready(physics_start_usec, step_result)
		return

	_apply_vertical_velocity(delta)
	_finalize_physics_step(physics_start_usec, pre_move_position, delta, step_result)


func _prepare_physics_step(delta: float) -> void:
	EnemyRuntimePolicy.tick_goal_runtime(_goal_runtime_state, delta)

	EnemyCrowdQuery.tick_local_cache(_crowd_query_state, delta)

	EnemyRuntimePolicy.tick_navigation_cache(_nav_cache_state, delta)

	if _telemetry != null:
		_telemetry.tick(delta)

	if _close_adjust_side_commit_remaining > 0.0:
		_close_adjust_side_commit_remaining = maxf(_close_adjust_side_commit_remaining - delta, 0.0)

	_melee_state_age += delta


func _run_horizontal_movement_phase(delta: float) -> PhysicsStepResult:
	var result: PhysicsStepResult = PhysicsStepResult.new()
	if not _has_valid_target():
		_target_node = null
		_resolve_target()

	if not _has_valid_target():
		_clear_goal_navigation_state()
		_set_horizontal_velocity(Vector3.ZERO)
		result.debug_state = "no target"
		return result

	var distance_to_target: float = _horizontal_distance_to(_target_node.global_position)
	var melee_state_start_usec := _profile_start_usec()
	_update_melee_state(_target_node.global_position)
	_record_profile_duration("melee_state", Time.get_ticks_usec() - melee_state_start_usec)
	result.debug_iteration_id = NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map())
	if result.debug_iteration_id == 0:
		_set_horizontal_velocity(Vector3.ZERO)
		result.debug_state = "nav not ready"
		result.nav_not_ready = true
		return result

	var state_result: EnemyMovementStateMachine.StateDispatchResult = _dispatch_movement_state(delta, distance_to_target)
	var state_motion_start_usec := _profile_start_usec()
	_apply_state_motion(state_result, delta)
	_record_profile_duration("state_motion", Time.get_ticks_usec() - state_motion_start_usec)
	result.debug_state = state_result.state
	result.debug_next_position = state_result.next_position
	result.attempted_horizontal_move = state_result.attempted_move

	if _apply_external_displacement(delta):
		result.attempted_horizontal_move = true

	return result


func _dispatch_movement_state(delta: float, distance_to_target: float) -> EnemyMovementStateMachine.StateDispatchResult:
	var profile_start_usec := _profile_start_usec()
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
	_record_profile_duration("state_dispatch", Time.get_ticks_usec() - profile_start_usec)
	return result


func _finalize_nav_not_ready(physics_start_usec: int, step_result: PhysicsStepResult) -> void:
	_update_debug()
	var move_slide_start_usec := _profile_start_usec()
	move_and_slide()
	_record_profile_duration("move_slide", Time.get_ticks_usec() - move_slide_start_usec)
	_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)


func _apply_vertical_velocity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0


func _finalize_physics_step(
	physics_start_usec: int,
	pre_move_position: Vector3,
	delta: float,
	step_result: PhysicsStepResult
) -> void:
	var finalize_start_usec := _profile_start_usec()
	var move_slide_start_usec := _profile_start_usec()
	move_and_slide()
	_record_profile_duration("move_slide", Time.get_ticks_usec() - move_slide_start_usec)
	var stuck_start_usec := _profile_start_usec()
	_update_stuck_state(delta, pre_move_position, step_result.attempted_horizontal_move)
	_record_profile_duration("stuck", Time.get_ticks_usec() - stuck_start_usec)
	var update_debug_start_usec := _profile_start_usec()
	_update_debug()
	_record_profile_duration("update_debug", Time.get_ticks_usec() - update_debug_start_usec)
	_record_profile_duration("finalize", Time.get_ticks_usec() - finalize_start_usec)
	_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)


# Goal selection and candidate scoring
func _should_refresh_goal() -> bool:
	EnemyDebugTelemetry.increment_counter("goal_refresh_checks")
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
	var should_refresh := EnemyRuntimePolicy.should_refresh_goal(request)
	if should_refresh:
		EnemyDebugTelemetry.increment_counter("goal_refresh_triggers")
	return should_refresh


func _select_engage_goal() -> void:
	var profile_start_usec := _profile_start_usec()
	_reset_goal_debug_state()
	if _target_node == null:
		_clear_goal_navigation_state()
		_goal_debug_state.candidate_positions = PackedVector3Array()
		_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
		return

	var target_position := _target_node.global_position
	var nearby_enemy_start_usec := _profile_start_usec()
	var nearby_enemy_positions := EnemyCrowdQuery.collect_nearby_enemy_positions(
		self,
		target_position,
		melee_engage_distance + spread_penalty_radius
	)
	_record_profile_duration("nearby_enemy", Time.get_ticks_usec() - nearby_enemy_start_usec)
	var goal_request: EnemyGoalSelector.SelectGoalRequest = EnemyGoalSelector.SelectGoalRequest.new()
	goal_request.target_position = target_position
	goal_request.global_position = global_position
	goal_request.melee_engage_distance = melee_engage_distance
	goal_request.engage_candidate_count = engage_candidate_count
	goal_request.capture_candidate_debug = _should_capture_candidate_debug()
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
	goal_request.distance_to_target = _horizontal_distance_to(target_position)
	goal_request.invalid_point = INVALID_POINT
	var goal_result: EnemyGoalSelector.GoalSelectionResult = EnemyGoalSelector.select_engage_goal(goal_request)
	_goal_debug_state.candidate_positions = goal_result.candidate_positions

	if not goal_result.has_goal:
		EnemyDebugTelemetry.increment_counter("goal_selection_failures")
		_clear_goal_navigation_state()
		_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
		return

	var apply_goal_request := EnemyRuntimePolicy.ApplyGoalSelectionRequest.new()
	apply_goal_request.goal_position = goal_result.goal_position
	apply_goal_request.goal_center = goal_result.goal_center
	apply_goal_request.goal_commit_duration = goal_commit_duration
	apply_goal_request.invalid_point = INVALID_POINT
	EnemyRuntimePolicy.apply_goal_selection(_goal_runtime_state, _nav_cache_state, apply_goal_request)
	EnemyDebugTelemetry.increment_counter("goal_selection_successes")
	if goal_result.debug != null and goal_result.debug.used_fallback:
		EnemyDebugTelemetry.increment_counter("goal_selection_fallbacks")
	_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)


func _reset_goal_select_cooldown() -> void:
	var cooldown_request := EnemyRuntimePolicy.GoalCooldownRequest.new()
	cooldown_request.goal_select_min_interval = goal_select_min_interval
	EnemyRuntimePolicy.reset_goal_select_cooldown(_goal_runtime_state, cooldown_request)


func _remember_failed_goal(goal_position: Vector3) -> void:
	var memory_request := EnemyRuntimePolicy.GoalMemoryRequest.new()
	memory_request.goal_position = goal_position
	memory_request.failed_goal_memory_count = failed_goal_memory_count
	EnemyRuntimePolicy.remember_failed_goal(_goal_runtime_state, memory_request)


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
		EnemyDebugTelemetry.increment_counter("frontline_checks")
		var frontline_start_usec := _profile_start_usec()
		var is_in_frontline := _is_in_active_melee_frontline(target_position)
		_record_profile_duration("frontline", Time.get_ticks_usec() - frontline_start_usec)
		if not is_in_frontline:
			next_state = EnemyCloseState.APPROACH

	if next_state == _melee_state:
		return

	_melee_state = next_state
	_melee_state_age = 0.0
	_melee_state_transition_count += 1
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
	var profile_start_usec := _profile_start_usec()
	if _target_node == null:
		_record_profile_duration("close_adjust", Time.get_ticks_usec() - profile_start_usec)
		return Vector3.ZERO

	EnemyDebugTelemetry.increment_counter("close_adjust_calls")
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
	_record_profile_duration("close_adjust", Time.get_ticks_usec() - profile_start_usec)
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


# Crowd-pressure response
func _compute_player_yield_velocity(allow_chain_pressure: bool = true) -> Vector3:
	var profile_start_usec := _profile_start_usec()
	if _target_node == null or crowd_pressure_yield_distance <= 0.0:
		_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
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
	var result: Vector3 = yield_result.velocity
	_record_profile_duration("yield", Time.get_ticks_usec() - profile_start_usec)
	return result


func _get_cached_local_enemy_positions(radius: float) -> Array[Vector3]:
	var profile_start_usec := _profile_start_usec()
	var positions: Array[Vector3] = EnemyCrowdQuery.get_cached_local_enemy_positions(
		self,
		global_position,
		radius,
		local_enemy_cache_interval,
		_crowd_query_state
	)
	_record_profile_duration("local_enemy", Time.get_ticks_usec() - profile_start_usec)
	return positions


# Locomotion and fallback
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

	var profile_start_usec := _profile_start_usec()
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
	_record_profile_duration("influence", Time.get_ticks_usec() - profile_start_usec)
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



# Debug presentation and logging
func _update_debug() -> void:
	if _telemetry == null:
		return
	if not _should_build_debug_snapshot():
		return
	_telemetry.update_debug(_build_debug_snapshot())


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
	return _resolve_navigation_next_position(move_target)


func _resolve_navigation_next_position(move_target: Vector3) -> Vector3:
	var profile_start_usec := _profile_start_usec()
	var next_position := EnemyNavigationLocomotion.resolve_navigation_next_position(
		_nav_agent,
		global_position,
		move_target
	)
	_record_profile_duration("nav_query", Time.get_ticks_usec() - profile_start_usec)
	return next_position


func _should_capture_candidate_debug() -> bool:
	return _telemetry != null and _telemetry.is_enemy_nav_path_enabled()


func _should_build_debug_snapshot() -> bool:
	return _telemetry != null and _telemetry.needs_debug_snapshot()


func _reset_goal_debug_state() -> void:
	_goal_debug_state.reset()


# Utility helpers
static func set_profiling_enabled(enabled: bool) -> void:
	EnemyDebugTelemetry.set_profiling_enabled(enabled)
	EnemyCrowdQuery.reset_profile_counters()


static func get_profile_snapshot() -> Dictionary:
	var snapshot: Dictionary = EnemyDebugTelemetry.get_profile_snapshot(EnemyCrowdQuery.get_registered_enemy_count())
	if snapshot.is_empty():
		return snapshot
	snapshot.merge(EnemyCrowdQuery.get_profile_counters(), true)
	return snapshot


func _profile_start_usec() -> int:
	return EnemyDebugTelemetry.profile_start_usec()


func _record_profile_duration(section: String, duration_usec: int) -> void:
	EnemyDebugTelemetry.record_profile_duration(section, duration_usec)


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




func _build_debug_snapshot() -> EnemyDebugSnapshot:
	var profile_start_usec := _profile_start_usec()
	var request: EnemyDebugSnapshotBuilder.BuildRequest = EnemyDebugSnapshotBuilder.BuildRequest.new()
	request.current_path = _nav_agent.get_current_navigation_path()
	request.has_goal = _goal_runtime_state.has_goal
	request.current_goal_position = _goal_runtime_state.current_goal_position
	request.debug_candidate_positions = _goal_debug_state.candidate_positions
	var snapshot: EnemyDebugSnapshot = EnemyDebugSnapshotBuilder.build(request)
	_record_profile_duration("snapshot", Time.get_ticks_usec() - profile_start_usec)
	return snapshot
