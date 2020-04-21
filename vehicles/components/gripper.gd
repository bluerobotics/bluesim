extends Spatial

var direction = 0
const speed = 0.4

func _ready():
	set_physics_process(true)
	$Area.contact_monitor = true
	$Area.contacts_reported = 1
	$Area.connect("body_entered", self, "_contact")
	$Area.connect("body_exited", self, "_exit_contact")

func _contact(node):
	print("inside", node)
	
func _exit_contact(node):
	print("outside", node)

func _physics_process(delta):
	if $"g1".rotation_degrees.z < 20 and direction > 0 \
		or $"g1".rotation_degrees.z > -6 and direction < 0:
		$"g1".rotate_z(direction * speed * delta)
		$"g2".rotate_z(-direction * speed * delta)
		
func open():
	direction = -1
	
func close():
	direction = 1

func stop():
	direction = 0

"""
func _input(event):
	if event.is_action_type():
		match event.as_text():
			"Up":
				direction = -1 if event.is_pressed() else 0
			"Down":
				direction = 1 if event.is_pressed() else 0
"""
