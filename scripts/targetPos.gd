extends Spatial

onready var rov = get_parent().find_node("cameraTarget", true, false)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	var distance = (self.global_transform.origin - rov.global_transform.origin)
	var length = distance.length()
	if length > 3:
		self.global_transform.origin =  rov.global_transform.origin + distance * 3/length
	self.look_at(rov.global_transform.origin, Vector3.UP)
