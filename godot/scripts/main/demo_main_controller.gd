extends Node3D


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_F3:
			get_tree().call_group("debug_overlay", "toggle_menu")
