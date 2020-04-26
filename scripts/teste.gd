extends Spatial

const BUOYANCY = 160.0 # newtons?
const HEIGHT = 2.4 # TODO: get this programatically

var underwater_env = load("res://underwaterEnvironment.tres")
var surface_env = load("res://default_env.tres")
# darkest it gets
var deep_color = underwater_env.background_color
onready var cameras = get_tree().get_nodes_in_group("cameras")
onready var surface_altitude = $water.translation.y

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)

func calculate_buoyancy():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if not vehicle is RigidBody:
			push_warning("Component %s does not inherit RigidBody." % vehicle.name)
			continue

		var buoyancy =  min(vehicle.buoyancy, abs(vehicle.buoyancy*(vehicle.translation.y - HEIGHT/2 - surface_altitude)))
		vehicle.add_force(Vector3(0, buoyancy, 0), vehicle.transform.basis.y*0.07)
	
func update_fog():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if not vehicle is RigidBody:
			push_warning("Component %s does not inherit RigidBody." % vehicle.name)
			continue
		var rov_camera = get_node(str(vehicle.get_path()) + "/Camera")
		var depth = rov_camera.global_transform.origin.y - surface_altitude
		var fog_distance = max(50 + 3 * depth, 20)
		underwater_env.fog_depth_end = fog_distance
		var new_color = Color("28a4e9").linear_interpolate(Color("001e5f"), 1-(fog_distance/55))
		underwater_env.background_color = new_color
		underwater_env.fog_color = new_color
		underwater_env.ambient_light_energy = fog_distance/100
		underwater_env.ambient_light_color = Color("a5d6f1").linear_interpolate(Color("001e5f"), 1-(fog_distance/50))

		for camera in cameras:
			depth = camera.global_transform.origin.y - surface_altitude
			camera.environment = surface_env if depth > 0 else underwater_env

func _physics_process(_delta):
	calculate_buoyancy()
	update_fog()
