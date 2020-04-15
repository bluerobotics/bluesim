extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const THRUST = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var gyro = $".".angular_velocity
	print("gyro:", gyro)
	
	pass
	
func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	var force_local = self.transform.basis.xform(force)
	$".".add_force(force_local, pos_local)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()
		if event.pressed and event.scancode == KEY_1:
			$".".add_force_local($t1.translation, Vector3(THRUST, 0, THRUST))
			
		if event.pressed and event.scancode == KEY_2:
			$".".add_force_local($t2.translation, Vector3(-THRUST, 0, THRUST))
			
		if event.pressed and event.scancode == KEY_3:
			$".".add_force_local($t3.translation, Vector3(THRUST, 0, -THRUST))
			
		if event.pressed and event.scancode == KEY_4:
			$".".add_force_local($t4.translation, Vector3(-THRUST, 0, -THRUST))
			
		if event.pressed and event.scancode == KEY_5:
			$".".add_force_local($t5.translation, Vector3(0, THRUST, 0))
			
		if event.pressed and event.scancode == KEY_6:
			$".".add_force_local($t6.translation, Vector3(0, THRUST, 0))
			
