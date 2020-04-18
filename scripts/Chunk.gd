# Thanks https://youtu.be/rWeQ30h25Yg

extends Spatial
class_name Chunk

var mesh
var noise
var x
var z
var chunk_size
var should_remove = true

func _init(noise, x, z, chunk_size):
	self.noise = noise
	self.x = x
	self.z = z
	self.chunk_size = chunk_size

func _ready():
	generate_chunk()
	generate_water()

func generate_chunk():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = chunk_size * 0.5
	plane_mesh.subdivide_width = chunk_size * 0.5
	plane_mesh.material = preload("res://imports/worn-blue-burlap-bl/worn-blue-burlap-bl.tres")

	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane, 0)

	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		# Chunk Height
		vertex.y = -30*abs(noise.get_noise_3d(vertex.x + x, vertex.y, vertex.z + z))

		data_tool.set_vertex(i, vertex)

	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)

	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()

	mesh = MeshInstance.new()
	mesh.mesh = surface_tool.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)

	# To Do give it a material
	plane_mesh.material = preload("res://imports/Water_001_SD/water_001_sd.tres")
	var water_mesh = MeshInstance.new()
	water_mesh.mesh = plane_mesh
	add_child(water_mesh)
