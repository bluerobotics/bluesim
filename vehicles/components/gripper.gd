extends Spatial

var direction = 0
const speed = 0.4

func _ready():
	set_physics_process(true)

func _contact(node):
	print("inside", node)
	
func _exit_contact(node):
	print("outside", node)

