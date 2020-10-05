extends Control

# Constant Gui Settings
const GUI_SIZE = Vector2(200, 0)
const DRAGGABLE = true

const CUSTOM_BACKGROUND = false
const BACKGROUND_COLOR = Color(0.15, 0.17, 0.23, 0.75)

var shortcut
var panel
var pos = Vector2(5, 5)

var mouse_over = false
var mouse_pressed = false

var fps_label
var labels = {}
var container


func _init(shortcut):
	self.shortcut = shortcut


func set_pos(pos):
	self.pos = pos


func update_label(name, value):
	if not name in self.labels:
		self.labels[name] = Label.new()
		self.container.add_child(self.labels[name])

	self.labels[name].set_text(name + ": " + str(value))


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

	self.container = VBoxContainer.new()

	var label = Label.new()
	label.set_text("Simulation (" + str(self.shortcut) + ")")

	$"/root/Node2D/ReferenceRect/ViewportGlobal".add_child(panel)
	panel.add_child(container)
	container.add_child(label)

	fps_label = Label.new()
	container.add_child(fps_label)

	if DRAGGABLE:
		panel.connect("mouse_entered", self, "_panel_entered")
		panel.connect("mouse_exited", self, "_panel_exited")
		container.connect("mouse_entered", self, "_panel_entered")
		container.connect("mouse_exited", self, "_panel_exited")


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


func _process(delta):
	_update_fps()


func _update_fps():
	if fps_label:
		fps_label.set_text("FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)))


func _panel_entered():
	mouse_over = true


func _panel_exited():
	mouse_over = false
