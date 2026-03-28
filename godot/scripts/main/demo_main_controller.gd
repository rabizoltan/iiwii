extends Node3D

const DEBUG_LINE_SCENE := preload("res://scenes/debug/DebugLine3D.tscn")

@onready var _spawn_warmup_manager: Node = $SpawnWarmupManager
@onready var _player: Node = $Actors/Player
@onready var _projectiles_root: Node = $Projectiles
@onready var _debug_world: Node = $DebugWorld


func _ready() -> void:
	_queue_runtime_warmups()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_F3:
			get_tree().call_group("debug_overlay", "toggle_menu")


func _queue_runtime_warmups() -> void:
	if _spawn_warmup_manager == null or not _spawn_warmup_manager.has_method("queue_scene_warmup"):
		return

	var projectile_scene := _player.get("projectile_scene") as PackedScene
	if projectile_scene != null:
		_spawn_warmup_manager.queue_scene_warmup(projectile_scene, _projectiles_root)

	_spawn_warmup_manager.queue_scene_warmup(DEBUG_LINE_SCENE, _debug_world)
