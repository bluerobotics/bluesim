extends Spatial

export var direction = 0

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	if Input.is_action_pressed("gripper_open"):
		self.direction = -1
	elif Input.is_action_pressed("gripper_close"):
		self.direction = 1

	$"../../joint3".set_param(6, direction)
	$"../../joint4".set_param(6, -direction)
	
