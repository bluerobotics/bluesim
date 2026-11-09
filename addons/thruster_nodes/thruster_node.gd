@tool

extends MeshInstance3D
var m = StandardMaterial3D.new()

@export var thickness = 0.01
@export var height = 0.1
@export var thrust = 1

@export var roll_factor: bool = true
@export var pitch_factor: bool = true
@export var yaw_factor: bool = true

@export var vertical_factor: bool = true
@export var forward_factor: bool = true
@export var lateral_factor: bool = true

# keeps track of transform changes to update motors matrix
var last_transform


func get_class():
	return "Thruster"


func _ready():
	last_transform = transform
	if Engine.is_editor_hint():
		set_process(true)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
		m.render_priority = m.RENDER_PRIORITY_MAX
		m.no_depth_test = true
		mesh = ImmediateMesh.new()
		material_override = m
	else:
		set_process(false)


func _process(_delta):
	if last_transform != transform:
		get_parent().calculate_motors_matrix()
		last_transform = transform

	mesh.clear_surfaces()

	# Begin draw.
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# base
	mesh.surface_add_vertex(Vector3(0, -thickness, -thickness))
	mesh.surface_add_vertex(Vector3(0, -thickness, thickness))

	mesh.surface_add_vertex(Vector3(0, -thickness, thickness))
	mesh.surface_add_vertex(Vector3(0, thickness, thickness))

	mesh.surface_add_vertex(Vector3(0, thickness, thickness))
	mesh.surface_add_vertex(Vector3(0, thickness, -thickness))

	mesh.surface_add_vertex(Vector3(0, thickness, -thickness))
	mesh.surface_add_vertex(Vector3(0, -thickness, -thickness))

	# walls
	mesh.surface_add_vertex(Vector3(0, -thickness, -thickness))
	mesh.surface_add_vertex(Vector3(height, -thickness, -thickness))

	mesh.surface_add_vertex(Vector3(0, -thickness, thickness))
	mesh.surface_add_vertex(Vector3(height, -thickness, thickness))

	mesh.surface_add_vertex(Vector3(0, thickness, thickness))
	mesh.surface_add_vertex(Vector3(height, thickness, thickness))

	mesh.surface_add_vertex(Vector3(0, thickness, -thickness))
	mesh.surface_add_vertex(Vector3(height, thickness, -thickness))

	# Hat
	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * -thickness))
	mesh.surface_add_vertex(Vector3(1.5 * height, 0, 0))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * -thickness))
	mesh.surface_add_vertex(Vector3(1.5 * height, 0, 0))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * thickness))
	mesh.surface_add_vertex(Vector3(1.5 * height, 0, 0))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * thickness))
	mesh.surface_add_vertex(Vector3(1.5 * height, 0, 0))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * -thickness))
	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * -thickness))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * -thickness))
	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * thickness))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * thickness, 1.3 * thickness))
	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * thickness))

	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * thickness))
	mesh.surface_add_vertex(Vector3(0.9 * height, 1.3 * -thickness, 1.3 * -thickness))
	# End drawing.
	mesh.surface_end()
