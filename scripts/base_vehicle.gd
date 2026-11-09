@tool
class_name BaseVehicle
extends RigidBody3D

const DEFAULT_SITL_JSON_PORT = 9002
const SITL_BIND_ADDRESS = "0.0.0.0"
const SERVO_HEADER_SIZE = 8
const SERVO_CHANNEL_BYTES = 2
const SERVO_FRAME_OFFSET = 4
const SERVO_CHANNELS = 16
const SERVO_MAGIC_BY_SIZE = {
	SERVO_HEADER_SIZE + SERVO_CHANNELS * SERVO_CHANNEL_BYTES: 18458,
	SERVO_HEADER_SIZE + 32 * SERVO_CHANNEL_BYTES: 29569,
}

@export_range(1, 65535) var sitl_json_port: int = DEFAULT_SITL_JSON_PORT

const MAX_PACKETS_PER_TICK = 32
const PEER_TIMEOUT_MS = 1000

var interface = PacketPeerUDP.new()
var peer_seen_at := -PEER_TIMEOUT_MS
var peer_ip := ""
var peer_port := 0
var last_servo_frame := -1
var servos := PackedInt32Array()

var last_velocity = Vector3(0, 0, 0)
var calculated_acceleration = Vector3(0, 0, 0)

var _initial_position: Vector3
var phys_time := 0.0
@onready var wait_SITL: bool = Globals.wait_SITL


func _ready():
	if Engine.is_editor_hint():
		return
	_initial_position = position
	if Globals.active_vehicle != null:
		return
	Globals.active_vehicle = self
	if not Globals.isHTML5:
		bind_sitl()


func _exit_tree():
	if not Engine.is_editor_hint() and Globals.active_vehicle == self:
		Globals.active_vehicle = null


func bind_sitl():
	if interface.bind(sitl_json_port, SITL_BIND_ADDRESS) != OK:
		push_warning(
			"ArduSub UDP port %d is unavailable. Keyboard controls remain active." % sitl_json_port
		)


func receive_servos() -> bool:
	var received := false
	for _packet_index in range(mini(interface.get_available_packet_count(), MAX_PACKETS_PER_TICK)):
		var packet := interface.get_packet()
		if (
			not SERVO_MAGIC_BY_SIZE.has(packet.size())
			or packet.decode_u16(0) != SERVO_MAGIC_BY_SIZE[packet.size()]
		):
			continue
		var sender_ip := interface.get_packet_ip()
		var sender_port := interface.get_packet_port()
		if interface.set_dest_address(sender_ip, sender_port) != OK:
			continue
		var frame := packet.decode_u32(SERVO_FRAME_OFFSET)
		if (
			frame != last_servo_frame
			or not has_sitl_peer()
			or sender_ip != peer_ip
			or sender_port != peer_port
		):
			servos.resize(SERVO_CHANNELS)
			for i in range(servos.size()):
				servos[i] = packet.decode_u16(SERVO_HEADER_SIZE + i * SERVO_CHANNEL_BYTES)
			last_servo_frame = frame
		peer_ip = sender_ip
		peer_port = sender_port
		peer_seen_at = Time.get_ticks_msec()
		received = true
	return received


func has_sitl_peer() -> bool:
	return Time.get_ticks_msec() - peer_seen_at < PEER_TIMEOUT_MS


func send_fdm():
	var _basis = transform.basis

	var toNED = Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))

	var toFRD = Basis(Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0))

	var _angular_velocity = toFRD * ((angular_velocity) * _basis)
	var gyro = [_angular_velocity.x, _angular_velocity.y, _angular_velocity.z]

	var _acceleration = toFRD * ((calculated_acceleration) * _basis)

	var accel = [_acceleration.x, _acceleration.y, _acceleration.z]

	var orientation = (
		Basis(-_basis.z, _basis.x, _basis.y)
		. rotated(Vector3(1, 0, 0), PI)
		. rotated(Vector3(1, 0, 0), PI / 2)
		. get_rotation_quaternion()
	)

	var _velocity = toNED * (self.linear_velocity)
	var velo = [_velocity.x, _velocity.y, _velocity.z]

	var _position = toNED * (self.transform.origin)
	var pos = [_position.x, _position.y, _position.z]

	var IMU_fmt = {"gyro": gyro, "accel_body": accel}
	var JSON_fmt = {
		"timestamp": phys_time,
		"imu": IMU_fmt,
		"position": pos,
		"quaternion": [orientation.w, orientation.x, orientation.y, orientation.z],
		"velocity": velo
	}
	var JSON_string = "\n" + JSON.stringify(JSON_fmt) + "\n"
	interface.put_packet(JSON_string.to_utf8_buffer())


func _physics_process(delta):
	if Engine.is_editor_hint() or Globals.active_vehicle != self:
		return
	phys_time += delta
	if Globals.isHTML5 or not interface.is_bound():
		process_keys()
		return
	calculated_acceleration = (linear_velocity - last_velocity) / delta
	calculated_acceleration.y += float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	last_velocity = linear_velocity
	var received := receive_servos()
	if not has_sitl_peer():
		process_keys()
		return
	for i in range(servos.size()):
		actuate_servo(i, clampf((servos[i] - 1000) / 1000.0, 0.0, 1.0))
	if received or not wait_SITL:
		send_fdm()


func add_force_local(force: Vector3, pos: Vector3):
	var pos_local = self.transform.basis * (pos)
	var force_local = self.transform.basis * (force)
	self.apply_force(force_local, pos_local)


func actuate_servo(_id: int, _percentage: float):
	pass


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("reset"):
		position = _initial_position


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
		self.apply_torque(self.transform.basis * (Vector3(0, 20, 0)))
	elif Input.is_action_pressed("rotate_right"):
		self.apply_torque(self.transform.basis * (Vector3(0, -20, 0)))
