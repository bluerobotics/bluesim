extends Spatial
const BUOYANCY = 10.0 # newtons?
const HEIGHT = 2.4 # TODO: get this programatically
var underwater_env = load("res://scenery/underwaterEnvironment.tres")
var surface_env = load("res://scenery/default_env.tres")
# darkest it gets
onready var cameras = get_tree().get_nodes_in_group("cameras")
onready var surface_altitude = $water.global_transform.origin.y

var fancy_water
var fancy_underwater
const simple_water = preload("res://assets/maujoe.basic_water_material/materials/basic_water_material.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)
	update_fog()

func calculate_buoyancy_and_ballast():
	var vehicles = get_tree().get_nodes_in_group("buoyant")
	for vehicle in vehicles:
		if not vehicle is RigidBody:
			push_warning("Component %s does not inherit RigidBody." % vehicle.name)
			continue

		var buoys = vehicle.find_node("buoys")
		if buoys:
			var children = buoys.get_children()
			for buoy in children:
				# print(buoy.transform.origin)
				var buoyancy =  vehicle.buoyancy*(surface_altitude - buoy.global_transform.origin.y)/children.size()
				if buoy.global_transform.origin.y > surface_altitude:
					buoyancy = 0
				vehicle.add_force_local_pos(Vector3(0, buoyancy, 0), buoy.transform.origin)
		else:
			var buoyancy =  min(vehicle.buoyancy, abs(vehicle.buoyancy*(vehicle.translation.y - HEIGHT/3 - surface_altitude)))
			vehicle.add_force(Vector3(0, buoyancy, 0), vehicle.transform.basis.y*0.07)
		var ballasts = vehicle.find_node("ballasts")
		if ballasts:
			var children = ballasts.get_children()
			for ballast in children:
				vehicle.add_force_local_pos(Vector3(0, -vehicle.ballast_kg*9.8, 0), ballast.transform.origin)
	
func update_fog():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if not vehicle is RigidBody:
			push_warning("Component %s does not inherit RigidBody." % vehicle.name)
			continue
		var rov_camera = get_node(str(vehicle.get_path()) + "/Camera")
		var depth = rov_camera.global_transform.origin.y - surface_altitude
		var fog_distance = max(50 + 1 * depth, 20)
		underwater_env.fog_depth_end = fog_distance
		var deep_factor = min(max(-depth/50, 0), 1.0)
		Globals.deep_factor = deep_factor
		var new_color = Globals.surface_ambient.linear_interpolate(Globals.deep_ambient, deep_factor)
		Globals.current_ambient = new_color.darkened(0.5)
		underwater_env.background_color = new_color
		underwater_env.background_sky.sky_horizon_color = new_color;
		underwater_env.background_sky.ground_bottom_color = new_color;
		underwater_env.background_sky.ground_horizon_color = new_color;
		underwater_env.fog_color = new_color
		underwater_env.ambient_light_energy = 1.0 - deep_factor
		# underwater_env.ambient_light_color = new_color;
		underwater_env.ambient_light_color = new_color; #surface_ambient.linear_interpolate(deep_ambient, max(1 - depth/50, 0))
		$sun.light_energy = max(0.3 - 0.5*deep_factor, 0)
		underwater_env.background_sky.sky_energy = max(5.0 - 5*deep_factor, 0.0)

		for camera in cameras:
			depth = camera.global_transform.origin.y - surface_altitude
			camera.environment = surface_env if depth > 0 else underwater_env
			if depth > 0:
				camera.cull_mask = 3
			else:
				camera.cull_mask = 5

func _physics_process(_delta):
	calculate_buoyancy_and_ballast()
	if not Globals.isHTML5:
		update_fog()

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		OS.kill(Globals.sitl_pid)
		get_tree().quit()


func _on_godrayToggle_toggled(button_pressed):
	$Godrays.emitting = button_pressed


func _on_dirtparticlesToggle_toggled(button_pressed):
	$SuspendedParticleHolder/SuspendedParticles.emitting = button_pressed


func _on_fancyWaterToggle_toggled(button_pressed):
	Globals.fancy_water = button_pressed
	if button_pressed:
		$water.set_surface_material(0, fancy_water)
		$underwater.set_surface_material(0, fancy_underwater)
	else:
		# save previous materials
		fancy_underwater = $underwater.get_surface_material(0)
		fancy_water = $water.get_surface_material(0)
		$water.set_surface_material(0, simple_water)
		$underwater.set_surface_material(0, simple_water)
