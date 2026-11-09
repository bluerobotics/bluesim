extends Camera3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Globals.active_vehicle:
		self.look_at(Globals.active_vehicle.transform.origin, Vector3(0, 1, 0))
