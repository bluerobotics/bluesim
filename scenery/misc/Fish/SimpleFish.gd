extends RigidBody

const close_ratio = 1.5
const ray_distance = 0.8
const ray_number = 4
var ray_array = []


func _ready():
	# Create ray cast vector
	for n in range(ray_number):
		var ray = RayCast.new()
		ray_array += [ray]
		ray.cast_to = Vector3(0, ray_distance, 0)
		ray.rotation = Vector3(
			cos(2 * PI * n / ray_number) / close_ratio + PI / 2,
			0,
			sin(2 * PI * n / ray_number) / close_ratio
		)
		ray.enabled = false
		add_child(ray)

# Loop variables
var result = Vector3(0, 0, 0)
var speed = 1
var total_collisions = 0
var raycast_frequency = 4
var raycast_total_time = 0

func _process(delta):
	raycast_total_time += delta

	# Run raycast in our own frequency for performance reasons
	if raycast_total_time > 1.0/raycast_frequency:
		raycast_total_time = 0
		result = Vector3(0, 0, 0)
		total_collisions = 0

		for ray in ray_array:
			# We don't need to enable the raycast to fetch it's information
			ray.force_raycast_update()
			if ray.is_colliding():
				total_collisions += 1
				result += ray.rotation

	# Correct fish attitude, no upside down
	if total_collisions == 0:
		var n1norm = self.global_transform.basis.y
		var cosa = n1norm.dot(Vector3.UP)
		var alpha = acos(cosa)
		var axis = n1norm.cross(Vector3.UP)
		axis = axis.normalized()
		self.add_torque(axis * alpha * 0.04)

	# Fish is stuck, we are going to get out around it
	elif total_collisions == ray_number:
		result = Vector3(PI / 2, 0, 0)
		speed *= -1

	self.apply_torque_impulse(self.global_transform.basis.xform(-result / 50000))
	var vec_speed = self.global_transform.basis.xform(Vector3(0, 0, 0.1))
	self.set_linear_velocity(speed * vec_speed)
