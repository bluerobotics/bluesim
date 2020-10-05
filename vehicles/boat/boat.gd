extends RigidBody

var interface = PacketPeerUDP.new()  # UDP socket for fdm in (server)
var peer = null
var start_time = OS.get_ticks_msec()

var last_velocity = Vector3(0, 0, 0)
var calculated_acceleration = Vector3(0, 0, 0)
var phys_time = 0

export var THRUST = 1000
var buoyancy = 2000 + self.mass * 9.8  # Newtons
export var CDx = 10.0  # lateral
export var CDz = 1000.0  # forward
export var CDy = 2000.0
export var Cl = 30.0
export var sail_CD = 8.5
export var sail_base_drag = 13.0
export var sail_Cl = 9.0
export var ballast_kg = 5.0
var rudder_angle = 0.0
var sail_angle = 0.0
var sail_tightness = 1.0
onready var _initial_position = get_global_transform().origin
onready var sail = get_parent().find_node("Sail", false, false)
# Called when the node enters the scene tree for the first time.
var CENTER = Vector3(0, 0, 0)


func _ready():
	set_physics_process(true)
	if typeof(Globals.active_vehicle) == TYPE_STRING and Globals.active_vehicle == "boat":
		Globals.active_vehicle = self
		#$Camera.current = true
	else:
		return
	if not Globals.isHTML5:
		connect_fmd_in()


func connect_fmd_in():
	if interface.listen(9002) != OK:
		print("Failed to connect fdm_in")


func get_servos():
	if not peer:
		interface.set_dest_address("127.0.0.1", interface.get_packet_port())

	if not interface.get_available_packet_count():
		if Globals.wait_SITL:
			interface.wait()
		else:
			return

	var buffer = StreamPeerBuffer.new()
	buffer.data_array = interface.get_packet()

	var magic = buffer.get_u16()
	buffer.seek(2)
	var _framerate = buffer.get_u16()

	buffer.seek(4)
	var _framecount = buffer.get_u16()

	if magic != 18458:
		return
	for i in range(0, 15):
		buffer.seek(8 + i * 2)
		actuate_servo(i, (float(buffer.get_u16()) - 1000) / 1000)


func send_fdm():
	var buffer = StreamPeerBuffer.new()
	buffer.put_double((OS.get_ticks_msec() - start_time) / 1000.0)
	var _basis = transform.basis
# These are the same but mean different things, let's keep both for now
	var toNED = Basis(Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0))
	toNED = Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	var toFRD = Basis(Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0))
	var _angular_velocity = toFRD.xform(_basis.xform_inv(angular_velocity))
	var gyro = [_angular_velocity.x, _angular_velocity.y, _angular_velocity.z]
	var _acceleration = toFRD.xform(_basis.xform_inv(calculated_acceleration))
	var accel = [_acceleration.x, _acceleration.y, _acceleration.z]
	var quaternon = Basis(-_basis.z, _basis.x, _basis.y).rotated(Vector3(1, 0, 0), PI).rotated(Vector3(1, 0, 0), PI / 2).get_rotation_quat()
	var euler = quaternon.get_euler()
	euler = [euler.y, euler.x, euler.z]
	var _velocity = toNED.xform(self.linear_velocity)
	var velo = [_velocity.x, _velocity.y, _velocity.z]
	var _position = toNED.xform(self.transform.origin)
	var pos = [_position.x, _position.y, _position.z]

	var wind = Vector3(-1, 0, 0).rotated(Vector3.UP, deg2rad(Globals.wind_dir)) * Globals.wind_speed
	var relative_wind = wind + self.linear_velocity

	var IMU_fmt = {"gyro": gyro, "accel_body": accel}
	var JSON_fmt = {
		"timestamp": phys_time,
		"imu": IMU_fmt,
		"position": pos,
		"quaternion": [quaternon.w, quaternon.x, quaternon.y, quaternon.z],
		"velocity": velo,
		"windvane":
		{
			"direction": relative_wind.angle_to(self.global_transform.basis.z),
			"speed": relative_wind.length()
		}
	}

	var JSON_string = "\n" + JSON.print(JSON_fmt) + "\n"
	buffer.put_utf8_string(JSON_string)
	interface.put_packet(buffer.data_array)


func _physics_process(delta):
	phys_time = phys_time + 1.0 / Globals.physics_rate
	process_keys()
	if Globals.isHTML5:
		return
	calculated_acceleration = (self.linear_velocity - last_velocity) / delta
	calculated_acceleration.y += 10
	last_velocity = self.linear_velocity
	get_servos()
	send_fdm()
	self.apply_drag_and_lift()
	$rudder.rotation_degrees.y = 90 + rudder_angle


func apply_drag_and_lift():
	var speeds = self.transform.basis.xform_inv(self.linear_velocity)
	var aoa = speeds.angle_to(Vector3(1.0, 0.0, 0.0))
	var drag_forward = -speeds.z * abs(speeds.z) * CDx
	var drag_lateral = -speeds.x * abs(speeds.x) * CDz
	var lift = speeds.length() * speeds.length() * Cl * sin(2 * aoa)
	self.add_force_local(Vector3(drag_lateral, 0, 0), CENTER)
	self.add_force_local(Vector3(0, 0, drag_forward), CENTER)
	self.add_force_local(Vector3(-lift, 0, 0), CENTER)

	self.add_torque(Vector3(0, clamp(THRUST * -100 * rudder_angle * speeds.z, -1000, 1000), 0))
	var wind = Vector3(-1, 0, 0).rotated(Vector3.UP, deg2rad(Globals.wind_dir)) * Globals.wind_speed

	var relative_wind = wind + self.linear_velocity

	var sail_to_wind_angle = (
		deg2rad(Globals.wind_dir)
		- sail.global_transform.basis.get_euler()[1]
		- PI / 2
	)
	var sail_to_relative_wind_angle = relative_wind.angle_to(sail.global_transform.basis.z)
	var sail_drag = (
		-relative_wind * sail_base_drag
		+ relative_wind * relative_wind * sail_CD * abs(sin(sail_to_relative_wind_angle))
	)

	#print ("loose_sail_angle:" , " ", rad2deg(loose_sail_angle))
	#sail_angle = loose_sail_angle

	var sail_lift = (relative_wind * relative_wind * sail_Cl * abs(sin(2 * sail_to_relative_wind_angle))).length()
	#print(rad2deg(sail_to_wind_angle), " ", sin(sail_to_wind_angle))
	#var pressure = -sin(sail_to_wind_angle)
	sail.add_force(sail_drag, Vector3(0, 1, 0))
	sail.add_force(
		Vector3(0, 0, sail_lift).rotated(Vector3.UP, sail.global_transform.basis.get_euler()[1]),
		CENTER
	)


func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	var force_local = self.transform.basis.xform(force)
	self.add_force(force_local, pos_local)


func add_force_local_pos(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	self.add_force(force, pos_local)


func actuate_servo(id, percentage):
	if percentage == 0:
		return
	match id:
		2:  # Motor
			#self.add_force_local(Vector3(0,0,(percentage-0.5)*THRUST),Vector3(0,0,0))
			pass
		0:
			rudder_angle = 90 * (percentage - 0.5)
		1:
			sail_tightness = 1.0 - percentage
			$SailJoint.set_param(1, sail_tightness * PI / 2)
			$SailJoint.set_param(2, -sail_tightness * PI / 2)


func process_keys():
	var speeds = self.transform.basis.xform_inv(self.linear_velocity)
	if Input.is_action_pressed("forward"):
		self.add_force_local(Vector3(0, 0, THRUST), CENTER)
	elif Input.is_action_pressed("backwards"):
		self.add_force_local(Vector3(0, 0, -THRUST), CENTER)

	if Input.is_action_pressed("rotate_left"):
		#rudder_angle -= 1
		#rudder_angle = clamp(rudder_angle, -45, 45)
		self.add_torque(Vector3(0, 2 * THRUST, 0))
	elif Input.is_action_pressed("rotate_right"):
		#rudder_angle += 1
		#rudder_angle = clamp(rudder_angle, -45, 45)
		self.add_torque(Vector3(0, -2 * THRUST, 0))
	if Input.is_action_pressed("sail_tighten"):
		sail_tightness = min(sail_tightness + 0.01, 1.0)
		$SailJoint.set_param(1, sail_tightness * PI / 2)
		$SailJoint.set_param(2, -sail_tightness * PI / 2)
	elif Input.is_action_pressed("sail_losen"):
		sail_tightness = max(sail_tightness - 0.01, 0.0)
		$SailJoint.set_param(1, sail_tightness * PI / 2)
		$SailJoint.set_param(2, -sail_tightness * PI / 2)
	if Input.is_action_pressed("reset"):
		set_translation(_initial_position)
