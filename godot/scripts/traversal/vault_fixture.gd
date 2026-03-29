extends Node3D

@export var landing_blocked: bool = false

@onready var _landing_blocker: StaticBody3D = $LandingBlocker
@onready var _landing_blocker_shape: CollisionShape3D = $LandingBlocker/CollisionShape3D


func _ready() -> void:
	_apply_landing_blocker_state()


func _apply_landing_blocker_state() -> void:
	if _landing_blocker != null:
		_landing_blocker.visible = landing_blocked

	if _landing_blocker_shape != null:
		_landing_blocker_shape.disabled = not landing_blocked
