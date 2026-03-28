extends Node

@export var hidden_world_position: Vector3 = Vector3(0.0, -1000.0, 0.0)

var _queued_warmups: Array[Dictionary] = []
var _is_processing_queue: bool = false


func queue_scene_warmup(scene: PackedScene, parent_node: Node) -> void:
	if scene == null or parent_node == null:
		return

	_queued_warmups.append({
		"scene": scene,
		"parent_node": parent_node,
	})

	if is_node_ready() and not _is_processing_queue:
		call_deferred("_process_warmup_queue")


func _ready() -> void:
	if not _queued_warmups.is_empty():
		call_deferred("_process_warmup_queue")


func _process_warmup_queue() -> void:
	if _is_processing_queue:
		return

	_is_processing_queue = true

	while not _queued_warmups.is_empty():
		var entry: Dictionary = _queued_warmups.pop_front()
		var scene: PackedScene = entry["scene"] as PackedScene
		var parent_node: Node = entry["parent_node"] as Node
		await _warm_scene_instance(scene, parent_node)

	_is_processing_queue = false


func _warm_scene_instance(scene: PackedScene, parent_node: Node) -> void:
	if scene == null or parent_node == null or not is_instance_valid(parent_node):
		return

	var instance: Node = scene.instantiate()
	if instance == null:
		return

	instance.process_mode = Node.PROCESS_MODE_DISABLED
	parent_node.add_child(instance)

	if instance is Node3D:
		(instance as Node3D).global_position = hidden_world_position

	await get_tree().process_frame
	await get_tree().physics_frame

	if is_instance_valid(instance):
		instance.queue_free()

	await get_tree().process_frame
