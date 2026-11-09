extends SceneTree

const TIMEOUT = 1.0


func _initialize():
	call_deferred("run")


func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition


func receive(client: PacketPeerUDP) -> PackedByteArray:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while client.get_available_packet_count() == 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	return client.get_packet() if client.get_available_packet_count() else PackedByteArray()


func servo_packet(channel_count: int, frame: int) -> PackedByteArray:
	var packet := PackedByteArray()
	packet.resize(8 + 2 * channel_count)
	packet.encode_u16(0, 18458 if channel_count == 16 else 29569)
	packet.encode_u16(2, 200)
	packet.encode_u32(4, frame)
	for channel in range(channel_count):
		packet.encode_u16(8 + channel * 2, 1500)
	return packet


func run():
	var globals := root.get_node("Globals")
	globals.active_vehicle = "bluerovheavy"
	globals.active_level = "res://levels/pool.tscn"
	globals.wait_SITL = true
	if not check(change_scene_to_file("res://levels/baselevel.tscn") == OK, "Pool failed to load"):
		return
	await scene_changed
	var vehicle: RigidBody3D = globals.active_vehicle
	if not check(vehicle.interface.is_bound(), "BlueSim did not bind UDP port 9002"):
		return

	var client := PacketPeerUDP.new()
	if not check(client.bind(0, "127.0.0.1") == OK, "Could not bind test UDP client"):
		return
	client.set_dest_address("127.0.0.1", 9002)
	client.put_packet(PackedByteArray([0, 1, 2]))
	var bad_magic := servo_packet(16, 2)
	bad_magic.encode_u16(0, 0)
	client.put_packet(bad_magic)
	if not check((await receive(client)).is_empty(), "BlueSim replied to malformed input"):
		return

	for channel_count in [16, 32]:
		var frame: int = 0x10000 + channel_count
		client.put_packet(servo_packet(channel_count, frame))
		var reply := (await receive(client)).get_string_from_utf8()
		if not check(reply.begins_with("\n{") and reply.ends_with("}\n"), "Invalid JSON framing"):
			return
		var state: Variant = JSON.parse_string(reply.strip_edges())
		if not check(state is Dictionary and state.has("imu") and state.has("quaternion"), "Invalid FDM state"):
			return
		if not check(vehicle.last_servo_frame == frame, "The servo frame counter was truncated"):
			return

	await create_timer(TIMEOUT + 0.1).timeout
	if not check(not vehicle.has_sitl_peer(), "SITL peer failed to expire"):
		return
	client.put_packet(servo_packet(16, 0))
	if not check(not (await receive(client)).is_empty(), "SITL did not reconnect"):
		return
	vehicle.interface.close()
	var blocker := PacketPeerUDP.new()
	if not check(blocker.bind(9002) == OK, "Could not occupy the port for the fallback test"):
		return
	vehicle.bind_sitl()
	if not check(not vehicle.interface.is_bound(), "BlueSim bound an occupied UDP port"):
		return
	var before: Vector3 = vehicle.global_position
	Input.action_press("forward")
	await create_timer(0.5).timeout
	Input.action_release("forward")
	var movement: Vector3 = vehicle.global_position - before
	if not check(Vector2(movement.x, movement.z).length() > 0.05, "Keyboard fallback did not move the vehicle"):
		return
	print("SITL transport passed: malformed packets, both layouts, framing, timeout, reconnect and occupied port")
	quit()
