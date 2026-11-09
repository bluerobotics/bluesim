@tool
extends BaseVehicle

const THRUST = 50
const ThrusterNode = preload("res://addons/thruster_nodes/thruster_node.gd")

@onready var buoyancy = 1.6 + self.mass * 9.8  # Newtons
@onready var light_glows = [$light_glow, $light_glow2, $light_glow3, $light_glow4]

@onready var ljoint = get_tree().get_root().find_child("ljoint", true, false)
@onready var rjoint = get_tree().get_root().find_child("rjoint", true, false)


func get_motors_table_entry(thruster):
	var thruster_vector = (thruster.transform.basis * Vector3(1, 0, 0)).normalized()
	var roll = Vector3(0, 0, -1).cross(thruster.position).normalized().dot(thruster_vector)
	var pitch = Vector3(1, 0, 0).cross(thruster.position).normalized().dot(thruster_vector)
	var yaw = Vector3(0, 1, 0).cross(thruster.position).normalized().dot(thruster_vector)
	var forward = Vector3(0, 0, -1).dot(thruster_vector)
	var lateral = Vector3(1, 0, 0).dot(thruster_vector)
	var vertical = Vector3(0, -1, 0).dot(thruster_vector)
	if abs(roll) < 0.15 or not thruster.roll_factor:
		roll = 0
	if abs(pitch) < 0.15 or not thruster.pitch_factor:
		pitch = 0
	if abs(yaw) < 0.15 or not thruster.yaw_factor:
		yaw = 0
	if abs(vertical) < 0.15 or not thruster.vertical_factor:
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
		if child is ThrusterNode:
			thrusters.append(child)
	for thruster in thrusters:
		var entry = get_motors_table_entry(thruster)
		entry.insert(0, i)
		i = i + 1
		print("add_motor_raw_6dof(AP_MOTORS_MOT_%s,\t%s,\t%s,\t%s,\t%s,\t%s,\t%s);" % entry)


func _ready():
	if Engine.is_editor_hint():
		calculate_motors_matrix()
		return
	super._ready()
	if Globals.active_vehicle == self:
		$Camera3D.make_current()


func actuate_servo(id: int, percentage: float):
	if percentage == 0:
		return

	var force = (percentage - 0.5) * 2 * -THRUST
	match id:
		0:
			self.add_force_local($t1.transform.basis * Vector3(force, 0, 0), $t1.position)
		1:
			self.add_force_local($t2.transform.basis * Vector3(force, 0, 0), $t2.position)
		2:
			self.add_force_local($t3.transform.basis * Vector3(force, 0, 0), $t3.position)
		3:
			self.add_force_local($t4.transform.basis * Vector3(force, 0, 0), $t4.position)
		4:
			self.add_force_local($t5.transform.basis * Vector3(force, 0, 0), $t5.position)
		5:
			self.add_force_local($t6.transform.basis * Vector3(force, 0, 0), $t6.position)
		6:
			self.add_force_local($t7.transform.basis * Vector3(force, 0, 0), $t7.position)
		7:
			self.add_force_local($t8.transform.basis * Vector3(force, 0, 0), $t8.position)
		8:
			$Camera3D.rotation_degrees.x = -45 + 90 * percentage
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
				ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 1)
				rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -1)
			elif percentage > 0.6:
				ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -1)
				rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 1)
			else:
				ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0)
				rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0)


func _unhandled_input(event: InputEvent):
	super._unhandled_input(event)
	if event is InputEventKey:
		# There are for debugging:
		# Some forces:
		if event.pressed and event.keycode == KEY_X:
			self.apply_central_force(Vector3(30, 0, 0))
		if event.pressed and event.keycode == KEY_Y:
			self.apply_central_force(Vector3(0, 30, 0))
		if event.pressed and event.keycode == KEY_Z:
			self.apply_central_force(Vector3(0, 0, 30))
		# Some torques
		if event.pressed and event.keycode == KEY_Q:
			self.apply_torque(self.transform.basis * (Vector3(15, 0, 0)))
		if event.pressed and event.keycode == KEY_T:
			self.apply_torque(self.transform.basis * (Vector3(0, 15, 0)))
		if event.pressed and event.keycode == KEY_E:
			self.apply_torque(self.transform.basis * (Vector3(0, 0, 15)))
		# Some hard-coded positions (used to check accelerometer)
		if event.pressed and event.keycode == KEY_U:
			self.look_at(Vector3(0, 100, 0), Vector3(0, 0, 1))  # expects +X
			freeze = true
		if event.pressed and event.keycode == KEY_I:
			self.look_at(Vector3(100, 0, 0), Vector3(0, 100, 0))  #expects +Z
			freeze = true
		if event.pressed and event.keycode == KEY_O:
			self.look_at(Vector3(100, 0, 0), Vector3(0, 0, -100))  #expects +Y
			freeze = true

		if event.pressed and event.is_action("camera_switch"):
			if $Camera3D.is_current():
				$Camera3D.clear_current(true)
			else:
				$Camera3D.make_current()

	if event.is_action_pressed("lights_up"):
		var percentage = min(max(0, $light1.light_energy + 0.1), 5)
		if percentage > 0 and light_glows[0].get_parent() == null:
			for light in light_glows:
				self.add_child(light)
		$light1.light_energy = percentage
		$light2.light_energy = percentage
		$light3.light_energy = percentage
		$light4.light_energy = percentage
		$scatterlight.light_energy = percentage * 0.5

	if event.is_action_pressed("lights_down"):
		var percentage = min(max(0, $light1.light_energy - 0.1), 5)
		$light1.light_energy = percentage
		$light2.light_energy = percentage
		$light3.light_energy = percentage
		$light4.light_energy = percentage
		$scatterlight.light_energy = percentage * 0.5
		if percentage == 0 and light_glows[0].get_parent() != null:
			for light in light_glows:
				self.remove_child(light)


func process_keys():
	super.process_keys()

	if Input.is_action_pressed("camera_up"):
		$Camera3D.rotation_degrees.x = min($Camera3D.rotation_degrees.x + 0.1, 45)
	elif Input.is_action_pressed("camera_down"):
		$Camera3D.rotation_degrees.x = max($Camera3D.rotation_degrees.x - 0.1, -45)

	if Input.is_action_pressed("gripper_open"):
		ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 1)
		rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -1)
	elif Input.is_action_pressed("gripper_close"):
		ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -1)
		rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 1)
	else:
		ljoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0)
		rjoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0)
