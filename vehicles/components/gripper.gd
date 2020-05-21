extends Spatial

var direction = 0
const speed = 0.4

func _ready():
	set_physics_process(true)

func _contact(node):
	print("inside", node)
	
func _exit_contact(node):
	print("outside", node)

func _physics_process(delta):
	if Input.is_action_pressed("gripper_open"):
		print("opening")
		open()
	elif Input.is_action_pressed("gripper_close"):
		close()
	else:
		stop()

	
func open():
	$"../../joint3".set_param(6, -1.0)
	$"../../joint4".set_param(6, 1.0)
	
func close():
	$"../../joint3".set_param(6, 1.0)
	$"../../joint4".set_param(6, -1.0)
	
func stop():
	$"../../joint3".set_param(6, 0.0)
	$"../../joint4".set_param(6, 0.0)
