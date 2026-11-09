extends Node3D


func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var vehicle = Globals.active_vehicle.find_child("cameraTarget", true, false)
	var distance = self.global_transform.origin - vehicle.global_transform.origin
	var length = distance.length()
	if length > 5:
		self.global_transform.origin = vehicle.global_transform.origin + distance * 5 / length
	self.look_at(vehicle.global_transform.origin, Vector3.UP)
