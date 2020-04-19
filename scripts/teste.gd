extends Spatial

const BUOYANCY = 160.0 # newtons?
const HEIGHT = 2.4 # TODO: get this programatically

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)

func calculate_buoyancy():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if not vehicle is RigidBody:
			push_warning("Component %s does not inherit RigidBody." % vehicle.name)
			continue

		var surface_altitude = $water.translation.y
		var buoyancy =  min(vehicle.buoyancy, abs(vehicle.buoyancy*(vehicle.translation.y - HEIGHT/2 - surface_altitude)))
		vehicle.add_force(Vector3(0, buoyancy, 0), vehicle.transform.basis.y*0.07)
	

func _physics_process(_delta):
	calculate_buoyancy()
	
