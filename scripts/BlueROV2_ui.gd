extends Control

# Constant Gui Settings
const GUI_SIZE = Vector2(200, 0)
const DRAGGABLE = true

const CUSTOM_BACKGROUND = false
const BACKGROUND_COLOR = Color(0.15, 0.17, 0.23, 0.75)

var servos
var servos_slider = []
var shortcut
var panel
var pos = Vector2(5, 5)

var mouse_over = false
var mouse_pressed = false

signal servos_changed(servos)

func _init(servos, shortcut):
	self.servos = servos
	self.shortcut = shortcut

func set_pos(pos):
	self.pos = pos

func _ready():
	set_process_input(true)
	# Create Gui
	panel = PanelContainer.new()
	panel.set_begin(self.pos)
	panel.set_custom_minimum_size(GUI_SIZE)

	if CUSTOM_BACKGROUND:
		var style = StyleBoxFlat.new()
		style.set_bg_color(BACKGROUND_COLOR)
		style.set_expand_margin_all(5)
		panel.add_stylebox_override("panel", style)

	var container = VBoxContainer.new()

	var label = Label.new()
	label.set_text("Servos (" + str(self.shortcut) + ")")

	$"/root/Node2D/ReferenceRect/ViewportGlobal".add_child(panel)
	panel.add_child(container)
	container.add_child(label)
	
	for i in range(16):
		var servo_label = Label.new()
		servo_label.set_text("Servo " + str(i))
	
		var scrool = HScrollBar.new()
		scrool.set_max(1)
		scrool.set_min(0)
		scrool.set_value(0.5)
		scrool.connect("value_changed", self, "_set_servo", [i])
		
		container.add_child(servo_label)
		container.add_child(scrool)
		servos_slider.append(scrool)

	if DRAGGABLE:
		panel.connect("mouse_entered", self, "_panel_entered")
		panel.connect("mouse_exited", self, "_panel_exited")
		container.connect("mouse_entered", self, "_panel_entered")
		container.connect("mouse_exited", self, "_panel_exited")
		
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 0.01
	timer.connect("timeout", self, "emit_servos") 
	add_child(timer)

func _input(event):
	if event.is_action_pressed(self.shortcut):
		if not self.panel.is_visible():
			self.panel.show()
		else:
			self.panel.hide()

	if DRAGGABLE:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			mouse_pressed = event.pressed

		elif event is InputEventMouseMotion and mouse_over and mouse_pressed:
			panel.set_begin(panel.get_begin() + event.relative)

func _panel_entered():
	mouse_over = true

func _panel_exited():
	mouse_over = false
	
func _set_servo(value, index):
	self.servos[index] = value

func emit_servos():
	emit_signal("servos_changed", self.servos)

func update_slider(index, value):
	self.servos_slider[index].set_value(value)
