extends RigidBody

const THRUST = 60

var fdm_in = PacketPeerUDP.new() # UDP socket for fdm in (server)
var fdm_out = PacketPeerUDP.new() # UDP socket for fdm out (client)
var start_time = OS.get_ticks_msec()

var last_velocity = Vector3(0, 0, 0);
var calculated_acceleration = Vector3(0, 0, 0);

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
	
	#double timestamp;  // in seconds
	buffer.put_double((OS.get_ticks_msec()-start_time)/1000.0)
	#double imu_angular_velocity_rpy[3];
	var _angular_velocity = self.transform.basis.xform(self.angular_velocity)
	buffer.put_double(_angular_velocity.x)
	buffer.put_double(_angular_velocity.z)
	buffer.put_double(-_angular_velocity.y)
	#double imu_linear_acceleration_xyz[3];
	var _acceleration = self.transform.basis.xform(calculated_acceleration)
	buffer.put_double(_acceleration.x)
	buffer.put_double(_acceleration.z)
	buffer.put_double(-_acceleration.y - 10)
	#double imu_orientation_quat[4];
	var orientation = Vector3(rotation.x, rotation.z, -rotation.y)
	var quaternon = Quat(orientation)
	buffer.put_double(quaternon.w)
	buffer.put_double(quaternon.x)
	buffer.put_double(quaternon.y)
	buffer.put_double(quaternon.z)
	#double velocity_xyz[3];
	var _velocity = self.transform.basis.xform(self.linear_velocity)
	buffer.put_double(_velocity.x)
	buffer.put_double(_velocity.z)
	buffer.put_double(-_velocity.y)
	#double position_xyz[3];
	buffer.put_double(global_transform.origin.x)
	buffer.put_double(global_transform.origin.z)
	buffer.put_double(-global_transform.origin.y)
	
	fdm_out.put_packet(buffer.data_array)
		
func _ready():
	set_physics_process(true)
	connect_fmd_in()

func _physics_process(delta):
	calculated_acceleration = (self.linear_velocity - last_velocity) / delta
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
			self.add_force_local(Vector3(force, 0, force), $t1.translation)
		1:
			self.add_force_local(Vector3(-force, 0, force), $t2.translation)
		2:
			self.add_force_local(Vector3(force, 0, -force), $t3.translation)
		3:
			self.add_force_local(Vector3(-force, 0, -force), $t4.translation)
		4:
			self.add_force_local(Vector3(0, force, 0), $t5.translation)
		5:
			self.add_force_local(Vector3(0, force, 0), $t6.translation)
			
