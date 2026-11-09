extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var vehicle


# Called when the node enters the scene tree for the first time.
func _ready():
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	if len(vehicles) == 0:
		print("unable to find a vehicle to follow!")
		return
	self.vehicle = vehicles[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not self.vehicle:
		return
	global_transform.origin = vehicle.global_transform.origin
	global_transform.basis = vehicle.global_transform.basis
