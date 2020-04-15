extends Spatial

const THRUST = 40

var fdm_in = PacketPeerUDP.new() # UDP socket for fdm in (server)
var fdm_out = PacketPeerUDP.new() # UDP socket for fdm out (client)
var start_time = OS.get_ticks_msec()

func connect_fmd_in():
	if fdm_in.listen(9002) != OK:
		print("Failed to connect fdm_in")

func connect_fdm_out():
	if (fdm_out.listen(9003, "0.0.0.0") != OK):
		print("Failed to connect fdm_out")

func get_servos():
	while fdm_in.get_available_packet_count():
		var buffer = StreamPeerBuffer.new()
		buffer.data_array = fdm_in.get_packet()
		print("-")
		for i in range(0, buffer.get_size()/4):
			buffer.seek(i*4)
			actuate_servo(i, buffer.get_float())

func send_fdm():
	if !fdm_out.is_listening():
		connect_fdm_out()

	fdm_out.set_dest_address("0.0.0.0", 9003)
	var buffer = StreamPeerBuffer.new()
	
	#double timestamp;  // in seconds
	buffer.put_double((OS.get_ticks_msec()-start_time)/1000.0)
	#double imu_angular_velocity_rpy[3];
	buffer.put_double($".".angular_velocity.x)
	buffer.put_double($".".angular_velocity.z)
	buffer.put_double(-$".".angular_velocity.y)
	#double imu_linear_acceleration_xyz[3];
	buffer.put_double(0)
	buffer.put_double(0)
	buffer.put_double(0)
	#double imu_orientation_quat[4];
	var orientation = Vector3(rotation.x, rotation.z, -rotation.y)
	var quaternon = Quat(orientation)
	buffer.put_double(quaternon.x)
	buffer.put_double(quaternon.y)
	buffer.put_double(quaternon.z)
	buffer.put_double(quaternon.w)
	#double velocity_xyz[3];
	buffer.put_double($".".linear_velocity.x)
	buffer.put_double($".".linear_velocity.z)
	buffer.put_double(-$".".linear_velocity.y)
	#double position_xyz[3];
	buffer.put_double(global_transform.origin.x)
	buffer.put_double(global_transform.origin.z)
	buffer.put_double(-global_transform.origin.y)
	
	fdm_out.put_packet(buffer.data_array)
		
func _ready():
	set_process(true) # Enable process call
	connect_fdm_out()
	connect_fmd_in()

func _process(delta):
	get_servos()
	send_fdm()
	
func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis.xform(pos)
	var force_local = self.transform.basis.xform(force)
	$".".add_force(force_local, pos_local)

#func _unhandled_input(event):
func actuate_servo(id, percentage):
	if percentage == 0:
		return

	var force = (percentage - 0.5) * THRUST
	if id == 0:
		$".".add_force_local($t1.translation, Vector3(force, 0, force))
		
	if id == 1:
		$".".add_force_local($t2.translation, Vector3(-force, 0, force))
		
	if id == 2:
		$".".add_force_local($t3.translation, Vector3(force, 0, -force))
		
	if id == 3:
		$".".add_force_local($t4.translation, Vector3(-force, 0, -force))
		
	if id == 4:
		$".".add_force_local($t5.translation, Vector3(0, force, 0))
		
	if id == 5:
		$".".add_force_local($t6.translation, Vector3(0, force, 0))
			
