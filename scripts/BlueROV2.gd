extends RigidBody

const THRUST = 20

var fdm_in = PacketPeerUDP.new() # UDP socket for fdm in (server)
var fdm_out = PacketPeerUDP.new() # UDP socket for fdm out (client)
var start_time = OS.get_ticks_msec()

var last_velocity = Vector3(0, 0, 0);
var calculated_acceleration = Vector3(0, 0, 0);

var buoyancy = 1.6 + self.mass * 9.8 # Newtons
var _initial_position = 0

func connect_fmd_in():
	if fdm_in.listen(9002) != OK:
		print("Failed to connect fdm_in")

func get_servos():
	while fdm_in.get_available_packet_count():
		var buffer = StreamPeerBuffer.new()
		buffer.data_array = fdm_in.get_packet()
		print("-")
		for i in range(0, buffer.get_size()/4):
			buffer.seek(i*4)
			actuate_servo(i, buffer.get_float())

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
	_initial_position = get_global_transform().origin
	set_physics_process(true)
	connect_fmd_in()


func _physics_process(delta):
	calculated_acceleration = (self.linear_velocity - last_velocity) / delta
	calculated_acceleration.y += 10
	last_velocity = self.linear_velocity
	get_servos()
	send_fdm()
	
func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	var force_local = self.transform.basis.xform(force)
	self.add_force(force_local, pos_local)

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
		if event.pressed and event.scancode == KEY_C:
			self.linear_velocity = Vector3(0,0,0)
		# Reset position
		if event.pressed and event.scancode == KEY_SPACE:
			set_translation(_initial_position)
		# Some torques
		if event.pressed and event.scancode == KEY_Q:
			self.add_torque(self.transform.basis.xform(Vector3(15,0,0)))
		if event.pressed and event.scancode == KEY_W:
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

