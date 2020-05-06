extends MeshInstance


var last_points = [[-1,0],[-1,0],[-1,0]]
var max_distance = 400
var n_offsets = 40
var max_offset = 0.3
var target_offsets = [0.0, 0.01, 0.02, 0.04, 0.07, 0.09, 0.11, 0.13, 0.15, 0.17, 0.18, 0.19, 0.21, 0.22, 0.25, 0.28]
	
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var angle = 0
var last_angle = angle
# ColorRect is the Node on which I have my shader material attached
var img = Image.new()
var texture = ImageTexture.new()

func _ready():
	# The array I want to send to my shader
	var new_targets = []
	var increment = 2*max_offset/n_offsets
	for i in range(int(n_offsets/2)):
		new_targets.append(-max_offset + i*increment)
		new_targets.append(max_offset - i*increment)
	target_offsets = new_targets
	print(target_offsets)
	var array = []
	for y in range(360):
		for x in range(100):
			array.append(0)
	

	# You'll have to get thoose the way you want
	var array_width = 100
	var array_heigh = 360

	# The following is used to convert the array into a Texture
	var byte_array = PoolByteArray(array)


	# I don't want any mipmaps generated : use_mipmaps = false
	# I'm only interested with 1 component per pixel (the corresponding array value) : Format = Image.FORMAT_R8
	img.create_from_data(array_width, array_heigh, false, Image.FORMAT_R8, byte_array)

	
func _physics_process(delta):
	if last_angle == angle:
		return
	var space_state = get_world().direct_space_state
	# use global coordinates, not local to node
	var target_list = []
	#var target_offsets = [0.0]
	for offset in target_offsets:
		target_list.append(global_transform.origin + self.global_transform.basis.xform(Vector3(0,max_distance*offset,max_distance).rotated(Vector3(0,1,0),deg2rad(angle))))
	last_points = []
	for cur_target in target_list:
		var result = space_state.intersect_ray(global_transform.origin, cur_target, [self])
		#$target.global_transform.origin = cur_target
		if 'position' in result:
			var distance_vector = global_transform.origin - result['position']
			var distance = distance_vector.length()*1000/max_distance
			var intensity = abs(result['normal'].dot(distance_vector.normalized()))
			last_points.append([distance, intensity])
	last_angle = angle

func _process(delta):
	angle = (angle + 1) % 360
	img.lock()
	for x in range(100):
		img.set_pixel(x, angle, 0)
	for point in last_points:
		var distance = point[0]
		var intensity = point[1]
		img.set_pixel(int(distance), angle, Color(intensity, intensity, intensity))

	img.unlock()
	#var image = texture.get_data()
	#img.set_pixel(angle, angle, 6)
	# Override the default flag with 0 since I don't want texture repeat/filtering/mipmaps/etc
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	# Upload the texture to my shader
	$display.get_surface_material(0).set_shader_param("my_array", texture)


