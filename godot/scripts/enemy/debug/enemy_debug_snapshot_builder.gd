extends RefCounted

const EnemyCloseState = preload("res://scripts/enemy/movement/enemy_close_state.gd")
const EnemyDebugSnapshot = preload("res://scripts/enemy/debug/enemy_debug_snapshot.gd")
const EnemyRuntimeState = preload("res://scripts/enemy/state/enemy_runtime_state.gd")


class BuildRequest:
	extends RefCounted

	var enemy_name: String = ""
	var global_position: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO
	var nav_target_position: Vector3 = Vector3.ZERO
	var debug_enabled: bool = false
	var debug_log_enabled: bool = false
	var melee_hold_debug_enabled: bool = false
	var show_hp_label: bool = true
	var current_hp: float = 0.0
	var max_hp: float = 0.0
	var melee_state: int = EnemyCloseState.APPROACH
	var melee_state_name: String = "unknown"
	var melee_state_age: float = 0.0
	var melee_state_transition_count: int = 0
	var has_goal: bool = false
	var current_goal_position: Vector3 = Vector3.ZERO
	var goal_age: float = 0.0
	var current_path: PackedVector3Array = PackedVector3Array()
	var stuck_elapsed: float = 0.0
	var distance_to_target: float = -1.0
	var distance_to_next: float = 0.0
	var horizontal_speed: float = 0.0
	var commanded_horizontal_speed: float = 0.0
	var actual_horizontal_displacement: float = 0.0
	var is_on_floor_now: bool = false
	var floor_normal: Vector3 = Vector3.ZERO
	var slide_collision_count: int = 0
	var slide_collision_names: Array[String] = []
	var nav_finished: bool = false
	var recovery_elapsed: float = 0.0
	var recovery_sign: float = 0.0
	var local_enemy_count: int = 0
	var ramp_collision_count: int = 0
	var enemy_collision_count: int = 0
	var melee_engage_distance: float = 0.0
	var engage_hold_tolerance: float = 0.0
	var melee_hold_displacement_log_threshold: float = 0.01
	var goal_debug_state: EnemyRuntimeState.GoalDebugState
	var close_adjust_debug_state: EnemyRuntimeState.CloseAdjustDebugState
	var hold_debug_state: EnemyRuntimeState.HoldDebugState
	var yield_debug_state: EnemyRuntimeState.YieldDebugState


static func build(request: BuildRequest) -> EnemyDebugSnapshot:
	var hold_limit: float = request.melee_engage_distance + request.engage_hold_tolerance
	var hold_margin: float = hold_limit - request.distance_to_target if request.distance_to_target >= 0.0 else -1.0
	var snapshot: EnemyDebugSnapshot = EnemyDebugSnapshot.new()
	snapshot.enemy_name = request.enemy_name
	snapshot.global_position = request.global_position
	snapshot.target_position = request.target_position
	snapshot.nav_target_position = request.nav_target_position
	snapshot.debug_enabled = request.debug_enabled
	snapshot.debug_log_enabled = request.debug_log_enabled
	snapshot.melee_hold_debug_enabled = request.melee_hold_debug_enabled
	snapshot.show_hp_label = request.show_hp_label
	snapshot.current_hp = request.current_hp
	snapshot.max_hp = request.max_hp
	snapshot.melee_state = request.melee_state
	snapshot.close_adjust_state = EnemyCloseState.CLOSE_ADJUST
	snapshot.melee_hold_state = EnemyCloseState.MELEE_HOLD
	snapshot.melee_state_name = request.melee_state_name
	snapshot.melee_state_age = request.melee_state_age
	snapshot.melee_state_transition_count = request.melee_state_transition_count
	snapshot.has_goal = request.has_goal
	snapshot.current_goal_position = request.current_goal_position
	snapshot.goal_age = request.goal_age
	snapshot.path_point_count = request.current_path.size()
	snapshot.current_path = request.current_path
	snapshot.stuck_elapsed = request.stuck_elapsed
	snapshot.distance_to_target = request.distance_to_target
	snapshot.distance_to_next = request.distance_to_next
	snapshot.horizontal_speed = request.horizontal_speed
	snapshot.commanded_horizontal_speed = request.commanded_horizontal_speed
	snapshot.actual_horizontal_displacement = request.actual_horizontal_displacement
	snapshot.is_on_floor_now = request.is_on_floor_now
	snapshot.floor_normal = request.floor_normal
	snapshot.slide_collision_count = request.slide_collision_count
	snapshot.slide_collision_names = request.slide_collision_names
	snapshot.nav_finished = request.nav_finished
	snapshot.recovery_elapsed = request.recovery_elapsed
	snapshot.recovery_sign = request.recovery_sign
	snapshot.local_enemy_count = request.local_enemy_count
	snapshot.ramp_collision_count = request.ramp_collision_count
	snapshot.enemy_collision_count = request.enemy_collision_count
	snapshot.debug_candidate_positions = request.goal_debug_state.candidate_positions
	snapshot.debug_nav_cache_refreshed = request.close_adjust_debug_state.nav_cache_refreshed
	snapshot.debug_close_adjust_path_distance = request.close_adjust_debug_state.path_distance
	snapshot.debug_close_adjust_target_gap = request.close_adjust_debug_state.target_gap
	snapshot.debug_close_adjust_crowd_pressure = request.close_adjust_debug_state.crowd_pressure
	snapshot.debug_close_adjust_left_penalty = request.close_adjust_debug_state.left_penalty
	snapshot.debug_close_adjust_right_penalty = request.close_adjust_debug_state.right_penalty
	snapshot.debug_close_adjust_side_sign = request.close_adjust_debug_state.side_sign
	snapshot.debug_close_adjust_lateral_weight = request.close_adjust_debug_state.lateral_weight
	snapshot.debug_close_adjust_move_speed = request.close_adjust_debug_state.move_speed
	snapshot.debug_hold_displacement = request.hold_debug_state.displacement
	snapshot.debug_hold_velocity = request.hold_debug_state.velocity
	snapshot.debug_hold_collision_count = request.hold_debug_state.collision_count
	snapshot.debug_hold_collision_names = request.hold_debug_state.collision_names
	snapshot.debug_hold_has_yield = request.hold_debug_state.has_yield
	snapshot.debug_yield_speed = request.yield_debug_state.speed
	snapshot.debug_yield_strength = request.yield_debug_state.strength
	snapshot.debug_yield_neighbor_count = request.yield_debug_state.neighbor_count
	snapshot.debug_yield_penalty = request.yield_debug_state.penalty
	snapshot.debug_yield_direction = request.yield_debug_state.direction
	snapshot.debug_crowd_pressure = request.yield_debug_state.crowd_pressure
	snapshot.debug_yield_direct_pressure = request.yield_debug_state.direct_pressure
	snapshot.debug_yield_chain_pressure = request.yield_debug_state.chain_pressure
	snapshot.debug_goal_candidate_count = request.goal_debug_state.candidate_count
	snapshot.debug_goal_rejected_projection_count = request.goal_debug_state.rejected_projection_count
	snapshot.debug_goal_rejected_failed_count = request.goal_debug_state.rejected_failed_count
	snapshot.debug_goal_unreachable_path_count = request.goal_debug_state.unreachable_path_count
	snapshot.debug_goal_used_fallback = request.goal_debug_state.used_fallback
	snapshot.debug_goal_raw_candidate = request.goal_debug_state.raw_candidate
	snapshot.debug_goal_projected_candidate = request.goal_debug_state.projected_candidate
	snapshot.debug_goal_projection_error = request.goal_debug_state.projection_error
	snapshot.debug_goal_selected_path_length = request.goal_debug_state.selected_path_length
	snapshot.debug_goal_path_end = request.goal_debug_state.path_end
	snapshot.debug_goal_path_end_error = request.goal_debug_state.path_end_error
	snapshot.hold_margin = hold_margin
	snapshot.melee_hold_displacement_log_threshold = request.melee_hold_displacement_log_threshold
	return snapshot
