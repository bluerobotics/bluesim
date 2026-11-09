extends SubViewportContainer

const SAMPLE_COUNT = 100
const ANGLE_COUNT = 360

var image := Image.create_empty(SAMPLE_COUNT, ANGLE_COUNT, false, Image.FORMAT_R8)
var texture := ImageTexture.create_from_image(image)


func _ready():
	material.set_shader_parameter("my_array", texture)
	var sonar := get_tree().get_first_node_in_group("ping360")
	if sonar:
		sonar.updatePing360Display.connect(on_ping360_update)


func on_ping360_update(angle, points):
	image.fill_rect(Rect2i(0, angle, SAMPLE_COUNT, 1), Color.BLACK)
	for point in points:
		var distance := clampi(int(point[0]), 0, SAMPLE_COUNT - 1)
		var intensity: float = point[1]
		image.set_pixel(distance, angle, Color(intensity, intensity, intensity))
	texture.update(image)


func _on_Ping360Toggle_toggled(button_pressed):
	Globals.ping360_enabled = button_pressed
	visible = button_pressed
