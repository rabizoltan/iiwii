extends CharacterBody3D

const EnemyCloseState = preload("res://scripts/enemy/movement/enemy_close_state.gd")
const EnemyMovementStateMachine = preload("res://scripts/enemy/movement/enemy_movement_state_machine.gd")
const EnemyGoalSelector = preload("res://scripts/enemy/movement/enemy_goal_selector.gd")
const EnemyCrowdResponse = preload("res://scripts/enemy/movement/enemy_crowd_response.gd")
const EnemyCrowdQuery = preload("res://scripts/enemy/movement/enemy_crowd_query.gd")
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

# Debug and health
@export var debug_enabled: bool = true
@export var debug_log_enabled: bool = false
@export var melee_hold_debug_enabled: bool = true
@export var show_hp_label: bool = true
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
@onready var _debug_label: Label3D = $DebugLabel3D
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
var _has_goal: bool = false
var _current_goal_position: Vector3 = Vector3.ZERO
var _goal_center_at_selection: Vector3 = Vector3.ZERO
var _goal_commit_remaining: float = 0.0
var _goal_select_cooldown_remaining: float = 0.0
var _goal_age: float = 0.0
var _recent_failed_goals: Array[Vector3] = []
var _goal_debug_state: EnemyRuntimeState.GoalDebugState
var _crowd_query_state: EnemyCrowdQuery.LocalEnemyCacheState
var _nav_refresh_remaining: float = 0.0
var _cached_nav_next_position: Vector3 = Vector3.ZERO
var _cached_nav_move_target: Vector3 = Vector3(INF, INF, INF)
var _movement_influence_state: EnemyRuntimeState.MovementInfluenceState
var _close_adjust_side_sign: float = 0.0
var _close_adjust_side_commit_remaining: float = 0.0
var _close_adjust_debug_state: EnemyRuntimeState.CloseAdjustDebugState
var _yield_debug_state: EnemyRuntimeState.YieldDebugState
var _hold_debug_state: EnemyRuntimeState.HoldDebugState

const MELEE_HOLD_DISPLACEMENT_LOG_THRESHOLD := 0.01
const INVALID_POINT := Vector3(INF, INF, INF)


# Lifecycle
func _enter_tree() -> void:
	EnemyCrowdQuery.register_enemy(self)


func _exit_tree() -> void:
	EnemyCrowdQuery.unregister_enemy(self)


func _ready() -> void:
	_current_hp = max_hp
	_goal_select_cooldown_remaining = randf() * maxf(goal_select_start_jitter, 0.0)
	_goal_debug_state = EnemyRuntimeState.GoalDebugState.new()
	_close_adjust_debug_state = EnemyRuntimeState.CloseAdjustDebugState.new()
	_yield_debug_state = EnemyRuntimeState.YieldDebugState.new()
	_hold_debug_state = EnemyRuntimeState.HoldDebugState.new()
	_movement_influence_state = EnemyRuntimeState.MovementInfluenceState.new()
	_crowd_query_state = EnemyCrowdQuery.LocalEnemyCacheState.new()
	_telemetry = EnemyDebugTelemetry.new()
	_telemetry.setup(self, _debug_label, _nav_path_debug)
	_nav_agent.set_navigation_map(get_world_3d().navigation_map)
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = engage_hold_tolerance
	call_deferred("_resolve_target")
	_telemetry.prepare_debug_log(debug_enabled, debug_log_enabled)
	_telemetry.prepare_melee_hold_debug_log(melee_hold_debug_enabled)


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
	_reset_yield_debug_state()
	_reset_close_adjust_debug_state()

	if _goal_commit_remaining > 0.0:
		_goal_commit_remaining = maxf(_goal_commit_remaining - delta, 0.0)

	if _goal_select_cooldown_remaining > 0.0:
		_goal_select_cooldown_remaining = maxf(_goal_select_cooldown_remaining - delta, 0.0)

	EnemyCrowdQuery.tick_local_cache(_crowd_query_state, delta)

	if _nav_refresh_remaining > 0.0:
		_nav_refresh_remaining = maxf(_nav_refresh_remaining - delta, 0.0)

	if _telemetry != null:
		_telemetry.tick(delta)

	if _close_adjust_side_commit_remaining > 0.0:
		_close_adjust_side_commit_remaining = maxf(_close_adjust_side_commit_remaining - delta, 0.0)

	if _has_goal:
		_goal_age += delta
	else:
		_goal_age = 0.0

	_melee_state_age += delta


func _run_horizontal_movement_phase(delta: float) -> PhysicsStepResult:
	var result: PhysicsStepResult = PhysicsStepResult.new()
	if not _has_valid_target():
		_target_node = null
		_resolve_target()

	if not _has_valid_target():
		_has_goal = false
		_invalidate_navigation_cache()
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
	_update_debug(step_result.debug_state, step_result.debug_next_position, step_result.debug_iteration_id)
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
	var hold_debug_start_usec := _profile_start_usec()
	_capture_melee_hold_runtime_debug(pre_move_position, step_result.debug_state, step_result.debug_next_position)
	_record_profile_duration("hold_debug", Time.get_ticks_usec() - hold_debug_start_usec)
	var stuck_start_usec := _profile_start_usec()
	_update_stuck_state(delta, pre_move_position, step_result.attempted_horizontal_move)
	_record_profile_duration("stuck", Time.get_ticks_usec() - stuck_start_usec)
	var update_debug_start_usec := _profile_start_usec()
	_update_debug(step_result.debug_state, step_result.debug_next_position, step_result.debug_iteration_id)
	_record_profile_duration("update_debug", Time.get_ticks_usec() - update_debug_start_usec)
	_record_profile_duration("finalize", Time.get_ticks_usec() - finalize_start_usec)
	_record_profile_duration("physics", Time.get_ticks_usec() - physics_start_usec)


# Goal selection and candidate scoring
func _should_refresh_goal() -> bool:
	if not _has_valid_target():
		return false

	if _goal_select_cooldown_remaining > 0.0:
		return false

	if not _has_goal:
		return true

	if _goal_commit_remaining > 0.0:
		return false

	var target_shift := _horizontal_distance(_goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return true

	var goal_distance := _horizontal_distance(global_position, _current_goal_position)
	return goal_distance <= maxf(engage_hold_tolerance, 0.25)


func _select_engage_goal() -> void:
	var profile_start_usec := _profile_start_usec()
	_reset_goal_debug_state()
	if _target_node == null:
		_has_goal = false
		_invalidate_navigation_cache()
		_goal_debug_state.candidate_positions = PackedVector3Array()
		_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
		return

	var target_position := _target_node.global_position
	var goal_request: EnemyGoalSelector.SelectGoalRequest = EnemyGoalSelector.SelectGoalRequest.new()
	goal_request.target_position = target_position
	goal_request.global_position = global_position
	goal_request.melee_engage_distance = melee_engage_distance
	goal_request.engage_candidate_count = engage_candidate_count
	goal_request.capture_candidate_debug = _should_capture_candidate_debug()
	goal_request.nearby_enemy_positions = EnemyCrowdQuery.collect_nearby_enemy_positions(
		self,
		target_position,
		melee_engage_distance + spread_penalty_radius
	)
	goal_request.navigation_map = _nav_agent.get_navigation_map()
	goal_request.navigation_layers = _nav_agent.navigation_layers
	goal_request.candidate_projection_tolerance = candidate_projection_tolerance
	goal_request.recent_failed_goals = _recent_failed_goals
	goal_request.failed_goal_exclusion_radius = failed_goal_exclusion_radius
	goal_request.spread_penalty_radius = spread_penalty_radius
	goal_request.spread_penalty_weight = spread_penalty_weight
	goal_request.goal_path_tiebreak_candidate_count = goal_path_tiebreak_candidate_count
	goal_request.goal_path_tiebreak_score_window = goal_path_tiebreak_score_window
	goal_request.goal_path_tiebreak_enemy_count_soft_limit = goal_path_tiebreak_enemy_count_soft_limit
	goal_request.goal_path_tiebreak_max_target_distance = goal_path_tiebreak_max_target_distance
	goal_request.enemy_count = EnemyCrowdQuery.get_registered_enemy_count()
	goal_request.distance_to_target = _horizontal_distance_to(target_position)
	goal_request.invalid_point = INVALID_POINT
	var goal_result: EnemyGoalSelector.GoalSelectionResult = EnemyGoalSelector.select_engage_goal(goal_request)
	var debug_info: EnemyGoalSelector.GoalDebugInfo = goal_result.debug
	_goal_debug_state.candidate_count = debug_info.candidate_count
	_goal_debug_state.rejected_projection_count = debug_info.rejected_projection_count
	_goal_debug_state.rejected_failed_count = debug_info.rejected_failed_count
	_goal_debug_state.used_fallback = debug_info.used_fallback
	_goal_debug_state.raw_candidate = debug_info.raw_candidate
	_goal_debug_state.projected_candidate = debug_info.projected_candidate
	_goal_debug_state.projection_error = debug_info.projection_error
	_goal_debug_state.candidate_positions = goal_result.candidate_positions

	if not goal_result.has_goal:
		_has_goal = false
		_invalidate_navigation_cache()
		_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)
		return

	_current_goal_position = goal_result.goal_position
	_goal_center_at_selection = goal_result.goal_center
	_goal_commit_remaining = goal_commit_duration
	_goal_age = 0.0
	_has_goal = true
	_invalidate_navigation_cache()
	_capture_goal_path_debug()
	_record_profile_duration("goal", Time.get_ticks_usec() - profile_start_usec)


func _reset_goal_select_cooldown() -> void:
	_goal_select_cooldown_remaining = maxf(goal_select_min_interval, 0.0)


func _remember_failed_goal(goal_position: Vector3) -> void:
	if failed_goal_memory_count <= 0:
		_recent_failed_goals.clear()
		return

	_recent_failed_goals.append(goal_position)
	while _recent_failed_goals.size() > failed_goal_memory_count:
		_recent_failed_goals.remove_at(0)


func _update_melee_state(target_position: Vector3) -> void:
	var request: EnemyMovementStateMachine.TransitionRequest = EnemyMovementStateMachine.TransitionRequest.new()
	request.global_position = global_position
	request.target_position = target_position
	request.close_adjust_enter_distance = close_adjust_enter_distance
	request.melee_engage_distance = melee_engage_distance
	request.engage_hold_tolerance = engage_hold_tolerance
	request.engage_vertical_tolerance = engage_vertical_tolerance
	var next_state := EnemyMovementStateMachine.compute_next_state(request)
	if next_state != EnemyCloseState.APPROACH and not _is_in_active_melee_frontline(target_position):
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


func _run_approach_state(_delta: float, distance_to_target: float) -> EnemyMovementStateMachine.StateDispatchResult:
	var move_target: Vector3 = _current_goal_position if _has_goal else _target_node.global_position
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
		_recovery_elapsed = maxf(_recovery_elapsed - _delta, 0.0)

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
	_close_adjust_debug_state.path_distance = close_adjust_result.debug_path_distance
	_close_adjust_debug_state.target_gap = close_adjust_result.debug_target_gap
	_close_adjust_debug_state.crowd_pressure = close_adjust_result.debug_crowd_pressure
	_close_adjust_debug_state.left_penalty = close_adjust_result.debug_left_penalty
	_close_adjust_debug_state.right_penalty = close_adjust_result.debug_right_penalty
	_close_adjust_debug_state.side_sign = close_adjust_result.debug_side_sign
	_close_adjust_debug_state.lateral_weight = close_adjust_result.debug_lateral_weight
	_close_adjust_debug_state.move_speed = close_adjust_result.debug_move_speed
	_close_adjust_side_sign = close_adjust_result.close_adjust_side_sign
	_close_adjust_side_commit_remaining = close_adjust_result.close_adjust_side_commit_remaining
	_record_profile_duration("close_adjust", Time.get_ticks_usec() - profile_start_usec)
	return close_adjust_result.velocity


func _get_close_adjust_move_target() -> Vector3:
	if _target_node == null:
		return global_position

	if not _has_goal:
		return _target_node.global_position

	var target_shift := _horizontal_distance(_goal_center_at_selection, _target_node.global_position)
	if target_shift >= goal_reacquire_distance:
		return _target_node.global_position

	return _current_goal_position


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
	_yield_debug_state.neighbor_count = yield_result.debug_neighbor_count
	_yield_debug_state.crowd_pressure = yield_result.debug_crowd_pressure
	_yield_debug_state.direct_pressure = yield_result.debug_direct_pressure
	_yield_debug_state.chain_pressure = yield_result.debug_chain_pressure
	_yield_debug_state.direction = yield_result.debug_direction
	_yield_debug_state.penalty = yield_result.debug_penalty
	_yield_debug_state.strength = yield_result.debug_strength
	_yield_debug_state.speed = yield_result.debug_speed
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
		if _has_goal:
			_remember_failed_goal(_current_goal_position)
			_has_goal = false
			_goal_commit_remaining = 0.0
			_invalidate_navigation_cache()
		_recovery_elapsed = stuck_recovery_duration
		_recovery_sign *= -1.0


func _capture_melee_hold_runtime_debug(pre_move_position: Vector3, state_text: String, next_position: Vector3) -> void:
	_hold_debug_state.reset()
	_hold_debug_state.has_yield = _yield_debug_state.speed > 0.01

	if _melee_state != EnemyCloseState.MELEE_HOLD:
		return

	var horizontal_delta := global_position - pre_move_position
	horizontal_delta.y = 0.0
	_hold_debug_state.displacement = horizontal_delta.length()
	_hold_debug_state.velocity = Vector2(velocity.x, velocity.z).length()
	if _telemetry == null or not _should_build_debug_snapshot(true):
		return
	if not _telemetry.can_append_melee_hold_debug_log(melee_hold_debug_enabled):
		return

	_hold_debug_state.collision_count = get_slide_collision_count()
	var collision_names: Array[String] = []
	for collision_index in range(_hold_debug_state.collision_count):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue

		var collider := collision.get_collider()
		if collider == null:
			collision_names.append("<null>")
			continue

		if collider is Node:
			collision_names.append((collider as Node).name)
		else:
			collision_names.append(str(collider))
	_hold_debug_state.collision_names = collision_names

	if _telemetry != null:
		_telemetry.append_melee_hold_debug_log(
			_build_debug_snapshot(_distance_to_target_or_default(), _horizontal_distance(global_position, next_position)),
			state_text,
			next_position
		)


# Debug presentation and logging
func _update_debug(state_text: String, next_position: Vector3, iteration_id: int) -> void:
	if _telemetry == null:
		return
	if not _should_build_debug_snapshot():
		return
	_telemetry.update_debug(
		_build_debug_snapshot(_distance_to_target_or_default(), _horizontal_distance(global_position, next_position)),
		state_text,
		next_position,
		iteration_id
	)


func _get_navigation_next_position(move_target: Vector3, distance_to_target: float) -> Vector3:
	_close_adjust_debug_state.nav_cache_refreshed = false
	if _should_refresh_navigation_cache(move_target, distance_to_target):
		_nav_agent.target_position = move_target
		_cached_nav_next_position = _resolve_navigation_next_position(move_target)
		_cached_nav_move_target = move_target
		_nav_refresh_remaining = _compute_nav_refresh_interval(distance_to_target)
		_close_adjust_debug_state.nav_cache_refreshed = true

	return _cached_nav_next_position if _cached_nav_next_position != Vector3.ZERO else move_target


func _should_refresh_navigation_cache(move_target: Vector3, distance_to_target: float) -> bool:
	var request: EnemyNavigationLocomotion.NavigationCacheRequest = EnemyNavigationLocomotion.NavigationCacheRequest.new()
	request.cached_nav_move_target = _cached_nav_move_target
	request.invalid_point = INVALID_POINT
	request.nav_refresh_remaining = _nav_refresh_remaining
	request.move_target = move_target
	request.recovery_elapsed = _recovery_elapsed
	request.melee_state = _melee_state
	request.approach_state = EnemyCloseState.APPROACH
	request.distance_to_target = distance_to_target
	request.nav_refresh_far_distance = nav_refresh_far_distance
	return EnemyNavigationLocomotion.should_refresh_navigation_cache(request)


func _compute_nav_refresh_interval(distance_to_target: float) -> float:
	var request: EnemyNavigationLocomotion.NavRefreshIntervalRequest = EnemyNavigationLocomotion.NavRefreshIntervalRequest.new()
	request.melee_state = _melee_state
	request.close_adjust_state = EnemyCloseState.CLOSE_ADJUST
	request.close_adjust_nav_refresh_interval = close_adjust_nav_refresh_interval
	request.distance_to_target = distance_to_target
	request.nav_refresh_far_distance = nav_refresh_far_distance
	request.nav_refresh_interval_near = nav_refresh_interval_near
	request.nav_refresh_interval_far = nav_refresh_interval_far
	return EnemyNavigationLocomotion.compute_nav_refresh_interval(request)


func _invalidate_navigation_cache() -> void:
	_nav_refresh_remaining = 0.0
	_cached_nav_next_position = Vector3.ZERO
	_cached_nav_move_target = INVALID_POINT


func _capture_goal_path_debug() -> void:
	if _telemetry == null:
		return
	var goal_path_debug: EnemyDebugTelemetry.GoalPathDebugInfo = _telemetry.capture_goal_path_debug(
		_nav_agent.get_current_navigation_path(),
		_current_goal_position
	)
	_goal_debug_state.path_end = goal_path_debug.path_end
	_goal_debug_state.path_end_error = goal_path_debug.path_end_error


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
	return debug_enabled and _telemetry != null and _telemetry.is_enemy_nav_path_enabled()


func _should_build_debug_snapshot(include_melee_hold_log: bool = false) -> bool:
	return _telemetry != null and _telemetry.needs_debug_snapshot(
		debug_enabled,
		show_hp_label,
		debug_log_enabled,
		melee_hold_debug_enabled if include_melee_hold_log else false
	)


func _reset_yield_debug_state() -> void:
	_yield_debug_state.reset()


func _reset_close_adjust_debug_state() -> void:
	_close_adjust_debug_state.reset()


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


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)


func _distance_to_target_or_default() -> float:
	if _target_node == null:
		return -1.0
	return _horizontal_distance(global_position, _target_node.global_position)


func _build_debug_snapshot(distance_to_target: float, distance_to_next: float) -> EnemyDebugSnapshot:
	var profile_start_usec := _profile_start_usec()
	var request: EnemyDebugSnapshotBuilder.BuildRequest = EnemyDebugSnapshotBuilder.BuildRequest.new()
	request.enemy_name = name
	request.global_position = global_position
	request.debug_enabled = debug_enabled
	request.debug_log_enabled = debug_log_enabled
	request.melee_hold_debug_enabled = melee_hold_debug_enabled
	request.show_hp_label = show_hp_label
	request.current_hp = _current_hp
	request.max_hp = max_hp
	request.melee_state = _melee_state
	request.melee_state_name = _get_melee_state_name()
	request.melee_state_age = _melee_state_age
	request.melee_state_transition_count = _melee_state_transition_count
	request.has_goal = _has_goal
	request.current_goal_position = _current_goal_position
	request.goal_age = _goal_age
	request.current_path = _nav_agent.get_current_navigation_path()
	request.stuck_elapsed = _stuck_elapsed
	request.distance_to_target = distance_to_target
	request.distance_to_next = distance_to_next
	request.melee_engage_distance = melee_engage_distance
	request.engage_hold_tolerance = engage_hold_tolerance
	request.melee_hold_displacement_log_threshold = MELEE_HOLD_DISPLACEMENT_LOG_THRESHOLD
	request.goal_debug_state = _goal_debug_state
	request.close_adjust_debug_state = _close_adjust_debug_state
	request.hold_debug_state = _hold_debug_state
	request.yield_debug_state = _yield_debug_state
	var snapshot: EnemyDebugSnapshot = EnemyDebugSnapshotBuilder.build(request)
	_record_profile_duration("snapshot", Time.get_ticks_usec() - profile_start_usec)
	return snapshot
