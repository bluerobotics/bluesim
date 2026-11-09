tool
extends "res://scripts/baseVehicle.gd"

const THRUST = 50
onready var light_glows = [$light_glow, $light_glow2, $light_glow3, $light_glow4]
onready var ljoint = get_tree().get_root().find_node("ljoint", true, false)
onready var rjoint = get_tree().get_root().find_node("rjoint", true, false)

var buoyancy = 1.6 + self.mass * 9.8  # Newtons


func _init():
	vehicle_name = "bluerovheavy"
	
func actuate_servo(id, percentage):
	if percentage == 0:
		return

	var force = (percentage - 0.5) * 2 * -THRUST
	match id:
		0:
			self.add_force_local($t1.transform.basis*Vector3(force,0,0), $t1.translation)
		1:
			self.add_force_local($t2.transform.basis*Vector3(force,0,0), $t2.translation)
		2:
			self.add_force_local($t3.transform.basis*Vector3(force,0,0), $t3.translation)
		3:
			self.add_force_local($t4.transform.basis*Vector3(force,0,0), $t4.translation)
		4:
			self.add_force_local($t5.transform.basis*Vector3(force,0,0), $t5.translation)
		5:
			self.add_force_local($t6.transform.basis*Vector3(force,0,0), $t6.translation)
		6:
			self.add_force_local($t7.transform.basis*Vector3(force,0,0), $t7.translation)
		7:
			self.add_force_local($t8.transform.basis*Vector3(force,0,0), $t8.translation)
		8:
			$Camera.rotation_degrees.x = -45 + 90 * percentage
		9:
			percentage -= 0.1
			$light1.light_energy = percentage * 5
			$light2.light_energy = percentage * 5
			$light3.light_energy = percentage * 5
			$light4.light_energy = percentage * 5
			$scatterlight.light_energy = percentage * 2.5
			if percentage < 0.01 and light_glows[0].get_parent() != null:
				for light in light_glows:
					self.remove_child(light)
			elif percentage > 0.01 and light_glows[0].get_parent() == null:
				for light in light_glows:
					self.add_child(light)

		10:
			if percentage < 0.4:
				ljoint.set_param(6, 1)
				rjoint.set_param(6, -1)
			elif percentage > 0.6:
				ljoint.set_param(6, -1)
				rjoint.set_param(6, 1)
			else:
				ljoint.set_param(6, 0)
				rjoint.set_param(6, 0)


func process_keys():
	if Input.is_action_pressed("forward"):
		self.add_force_local(Vector3(0, 0, 40), Vector3(0, -0.05, 0))
	elif Input.is_action_pressed("backwards"):
		self.add_force_local(Vector3(0, 0, -40), Vector3(0, -0.05, 0))

	if Input.is_action_pressed("strafe_right"):
		self.add_force_local(Vector3(-40, 0, 0), Vector3(0, -0.05, 0))
	elif Input.is_action_pressed("strafe_left"):
		self.add_force_local(Vector3(40, 0, 0), Vector3(0, -0.05, 0))

	if Input.is_action_pressed("upwards"):
		self.add_force_local(Vector3(0, 70, 0), Vector3(0, -0.05, 0))
	elif Input.is_action_pressed("downwards"):
		self.add_force_local(Vector3(0, -70, 0), Vector3(0, -0.05, 0))

	if Input.is_action_pressed("rotate_left"):
		self.add_torque(self.transform.basis.xform(Vector3(0, 20, 0)))
	elif Input.is_action_pressed("rotate_right"):
		self.add_torque(self.transform.basis.xform(Vector3(0, -20, 0)))

	if Input.is_action_pressed("camera_up"):
		$Camera.rotation_degrees.x = min($Camera.rotation_degrees.x + 0.1, 45)
	elif Input.is_action_pressed("camera_down"):
		$Camera.rotation_degrees.x = max($Camera.rotation_degrees.x - 0.1, -45)

	if Input.is_action_pressed("gripper_open"):
		ljoint.set_param(6, 1)
		rjoint.set_param(6, -1)
	elif Input.is_action_pressed("gripper_close"):
		ljoint.set_param(6, -1)
		rjoint.set_param(6, 1)
	else:
		ljoint.set_param(6, 0)
		rjoint.set_param(6, 0)
	
	if Input.is_action_pressed("lights_up"):
		var percentage = min(max(0, $light1.light_energy + 0.1), 5)
		if percentage > 0:
			for light in light_glows:
				self.add_child(light)
		$light1.light_energy = percentage
		$light2.light_energy = percentage
		$light3.light_energy = percentage
		$light4.light_energy = percentage
		$scatterlight.light_energy = percentage * 0.5

	if Input.is_action_pressed("lights_down"):
		var percentage = min(max(0, $light1.light_energy - 0.1), 5)
		$light1.light_energy = percentage
		$light2.light_energy = percentage
		$light3.light_energy = percentage
		$light4.light_energy = percentage
		$scatterlight.light_energy = percentage * 0.5
		if percentage == 0:
			for light in light_glows:
				self.remove_child(light)

func get_motors_table_entry(thruster):

	var thruster_vector = (thruster.transform.basis*Vector3(1,0,0)).normalized()
	var roll = Vector3(0,0,-1).cross(thruster.translation).normalized().dot(thruster_vector)
	var pitch = Vector3(1,0,0).cross(thruster.translation).normalized().dot(thruster_vector)
	var yaw = Vector3(0,1,0).cross(thruster.translation).normalized().dot(thruster_vector)
	var forward = Vector3(0,0,-1).dot(thruster_vector)
	var lateral = Vector3(1,0,0).dot(thruster_vector)
	var vertical = Vector3(0,-1,0).dot(thruster_vector)
	if abs(roll) < 0.15 or not thruster.roll_factor:
		roll = 0
	if abs(pitch) < 0.15 or not thruster.pitch_factor:
		pitch = 0
	if abs(yaw) < 0.15 or not thruster.yaw_factor:
		yaw = 0
	if abs(vertical) < 0.15 or not thruster.vertical_factor :
		vertical = 0
	if abs(forward) < 0.15 or not thruster.forward_factor:
		forward = 0
	if abs(lateral) < 0.15 or not thruster.lateral_factor:
		lateral = 0
	return [roll, pitch, yaw, vertical, forward, lateral]

func calculate_motors_matrix():
	print("Calculated Motors Matrix:")
	var thrusters = []
	var i = 1
	for child in get_children():
		if child.get_class() ==  "Thruster":
			thrusters.append(child)
	for thruster in thrusters:
		var entry = get_motors_table_entry(thruster)
		entry.insert(0, i)
		i = i + 1
		print("add_motor_raw_6dof(AP_MOTORS_MOT_%s,\t%s,\t%s,\t%s,\t%s,\t%s,\t%s);" % entry)

func on_ready():
	if Engine.is_editor_hint():
		calculate_motors_matrix()
