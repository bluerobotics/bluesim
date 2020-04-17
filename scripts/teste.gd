extends Spatial

const BUOYANCY = 160.0 # newtons?
const HEIGHT = 2.0 # TODO: get this programatically

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func calculate_buoyancy():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		var surface_altitude = $surface.translation.y
		var buoyancy =  min(BUOYANCY, abs(BUOYANCY*(vehicle.translation.y - HEIGHT/2 - surface_altitude)))
		vehicle.add_force(Vector3(0, buoyancy, 0), vehicle.transform.basis.y*0.5)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	calculate_buoyancy()
	
