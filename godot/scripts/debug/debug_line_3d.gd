extends MeshInstance3D

var _remaining_life: float = 0.0


func setup(start_position: Vector3, end_position: Vector3, line_color: Color, duration: float) -> void:
	global_position = Vector3.ZERO
	_remaining_life = duration

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = line_color
	material.vertex_color_use_as_albedo = true

	var line_mesh: ImmediateMesh = ImmediateMesh.new()
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	line_mesh.surface_set_color(line_color)
	line_mesh.surface_add_vertex(start_position)
	line_mesh.surface_add_vertex(end_position)
	line_mesh.surface_end()
	mesh = line_mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_remaining_life -= delta
	if _remaining_life <= 0.0:
		queue_free()
