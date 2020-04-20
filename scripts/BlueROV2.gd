extends RigidBody

const THRUST = 20

var fdm_in = PacketPeerUDP.new() # UDP socket for fdm in (server)
var fdm_out = PacketPeerUDP.new() # UDP socket for fdm out (client)
var start_time = OS.get_ticks_msec()

var last_velocity = Vector3(0, 0, 0);
var calculated_acceleration = Vector3(0, 0, 0);

var buoyancy = 1.6 + self.mass * 9.8 # Newtons
var _initial_position = 0

# Gui settings
export var use_gui = true
export var gui_action = "F1"
var _gui
var _gui_system

const NUMBER_OF_SERVOS = 16
var servos = [0]

func connect_fmd_in():
	if fdm_in.listen(9002) != OK:
		print("Failed to connect fdm_in")

func get_servos():
	var got_servo = false
	while fdm_in.get_available_packet_count():
		got_servo = true
		var buffer = StreamPeerBuffer.new()
		buffer.data_array = fdm_in.get_packet()
		print("-")
		for i in range(0, buffer.get_size()/4):
			buffer.seek(i*4)
			self.servos[i] = buffer.get_float()
			_gui.update_slider(i, self.servos[i])
	
	if got_servo:
		update_servos()

func send_fdm():

	fdm_out.set_dest_address("127.0.0.1", 9003)
	var buffer = StreamPeerBuffer.new()

	buffer.put_double((OS.get_ticks_msec()-start_time)/1000.0)

	var _basis =  transform.basis

# These are the same but mean different things, let's keep both for now
	var toNED = Basis(Vector3(0, -1, 0)
					 ,Vector3(0, 0, -1)
					 ,Vector3(1, 0, 0))

	var toFRD = Basis(Vector3(0, -1, 0)
					 ,Vector3(0, 0, -1)
					 ,Vector3(1, 0, 0))

	var _angular_velocity = toFRD.xform(_basis.xform_inv(angular_velocity))
	buffer.put_double(_angular_velocity.x)
	buffer.put_double(_angular_velocity.y)
	buffer.put_double(_angular_velocity.z)

	var _acceleration = toFRD.xform(_basis.xform_inv(calculated_acceleration))
	buffer.put_double(_acceleration.x)
	buffer.put_double(_acceleration.y)
	buffer.put_double(_acceleration.z)

	var orientation = toFRD.xform(Vector3(rotation.x, rotation.y, rotation.z))
	var quaternon = Quat(orientation)
	buffer.put_double(quaternon.w)
	buffer.put_double(quaternon.x)
	buffer.put_double(quaternon.y)
	buffer.put_double(quaternon.z)

	var _velocity = toNED.xform(self.linear_velocity)
	buffer.put_double(_velocity.x)
	buffer.put_double(_velocity.y)
	buffer.put_double(_velocity.z)

	var _position = toNED.xform(self.transform.origin)
	buffer.put_double(_position.x)
	buffer.put_double(_position.y)
	buffer.put_double(_position.z)

	fdm_out.put_packet(buffer.data_array)

func _ready():
	for id in range(0, NUMBER_OF_SERVOS):
		self.servos.append(0)
		
	_initial_position = get_global_transform().origin
	set_physics_process(true)
	connect_fmd_in()

	if use_gui:
		_gui = preload("BlueROV2_ui.gd")
		_gui = _gui.new(self.servos, gui_action)
		add_child(_gui)
		_gui.connect("servos_changed", self, "got_servos")

		_gui_system = preload("SimulationState.gd").new("F2")
		add_child(_gui_system)

func _physics_process(delta):
	process_keys()
	calculated_acceleration = (self.linear_velocity - last_velocity) / delta
	calculated_acceleration.y += 10
	last_velocity = self.linear_velocity
	get_servos()
	send_fdm()
	
func _process(delta):
	_gui_system.update_label("Position", self.transform.origin)
	_gui_system.update_label("Velocity", self.linear_velocity)
	_gui_system.update_label("Orientation", self.rotation_degrees)

func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	var force_local = self.transform.basis.xform(force)
	self.add_force(force_local, pos_local)

func got_servos(servos):
	self.servos = servos
	update_servos()

func update_servos():
	for id in range(0, self.servos.size()):
		actuate_servo(id, self.servos[id])

func actuate_servo(id, percentage):
	if percentage == 0:
		return

	var force = (percentage - 0.5) * 2 * THRUST
	match id:
		0:
			self.add_force_local(Vector3(-force, 0, -force), $t1.translation)
		1:
			self.add_force_local(Vector3(force, 0, -force), $t2.translation)
		2:
			self.add_force_local(Vector3(-force, 0, force), $t3.translation)
		3:
			self.add_force_local(Vector3(force, 0, force), $t4.translation)
		4:
			self.add_force_local(Vector3(0, -force, 0), $t5.translation)
		5:
			self.add_force_local(Vector3(0, -force, 0), $t6.translation)
		8:
			$Camera.rotation_degrees.x = 80 * (percentage - 0.5)
		9:
			# Move lights power to be inside BlueROV2 model
			$light1.light_energy = 10 * percentage
			$light2.light_energy = $light1.light_energy
		10:
			if percentage > 0.5: 
				$Gripper.close()
			else:
				$Gripper.open()
		
func _unhandled_input(event):
	if event is InputEventKey:
		# There are for debugging:
		# Some forces:
		if event.pressed and event.scancode == KEY_X:
			self.add_central_force(Vector3(30, 0, 0))
		if event.pressed and event.scancode == KEY_Y:
			self.add_central_force(Vector3(0, 30, 0))
		if event.pressed and event.scancode == KEY_Z:
			self.add_central_force(Vector3(0, 0, 30))
		# kills linear velocity
		#if event.pressed and event.scancode == KEY_C:
			#self.linear_velocity = Vector3(0,0,0)
		# Reset position
		if event.pressed and event.scancode == KEY_R:
			set_translation(_initial_position)
		# Some torques
		if event.pressed and event.scancode == KEY_Q:
			self.add_torque(self.transform.basis.xform(Vector3(15,0,0)))
		if event.pressed and event.scancode == KEY_T:
			self.add_torque(self.transform.basis.xform(Vector3(0,15,0)))
		if event.pressed and event.scancode == KEY_E:
			self.add_torque(self.transform.basis.xform(Vector3(0,0,15)))
		# Some hard-coded positions (used to check accelerometer)
		if event.pressed and event.scancode == KEY_U:
			self.look_at(Vector3(0,100,0),Vector3(0,0,1)) # expects +X
			mode = RigidBody.MODE_STATIC
		if event.pressed and event.scancode == KEY_I:
			self.look_at(Vector3(100,0,0),Vector3(0,100,0)) #expects +Z
			mode = RigidBody.MODE_STATIC
		if event.pressed and event.scancode == KEY_O:
			self.look_at(Vector3(100,0,0),Vector3(0,0,-100)) #expects +Y
			mode = RigidBody.MODE_STATIC

func process_keys():
	if Input.is_action_pressed("forward"):
		self.add_force_local(Vector3(0,0,40),Vector3(0,0,0))
	if Input.is_action_pressed("backwards"):
		self.add_force_local(Vector3(0,0,-40),Vector3(0,0,0))
	if Input.is_action_pressed("strafe_right"):
		self.add_force_local(Vector3(-40,0,0),Vector3(0,0,0))
	if Input.is_action_pressed("strafe_left"):
		self.add_force_local(Vector3(40,0,0),Vector3(0,0,0))
	if Input.is_action_pressed("upwards"):
		self.add_force_local(Vector3(0,70,0),Vector3(0,0,0))
	if Input.is_action_pressed("downwards"):
		self.add_force_local(Vector3(0,-70,0),Vector3(0,0,0))
	if Input.is_action_pressed("rotate_left"):
		self.add_torque(self.transform.basis.xform(Vector3(0,-20,0)))
	if Input.is_action_pressed("rotate_right"):
		self.add_torque(self.transform.basis.xform(Vector3(0,20,0)))
