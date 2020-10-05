extends PanelContainer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var boat = get_tree().get_root().find_node("SailBoat", true, false)


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/windDirectionSlider.value = Globals.wind_dir
	$VBoxContainer/windSpeedSlider.value = Globals.wind_speed
	$VBoxContainer/cdxSlider.value = boat.CDx
	$VBoxContainer/cdySlider.value = boat.CDy
	$VBoxContainer/hullClSlider.value = boat.Cl
	$VBoxContainer/sailcdSlider.value = boat.sail_CD
	$VBoxContainer/sailBaseDragSlider.value = boat.sail_base_drag
	$VBoxContainer/sailClSlider.value = boat.sail_Cl
	$VBoxContainer/ballastSlider.value = boat.ballast_kg


func _input(event):
	if event.is_action_pressed("F1"):
		if not self.is_visible():
			self.show()
		else:
			self.hide()


func _on_windDirectionSlider_value_changed(value):
	Globals.wind_dir = $VBoxContainer/windDirectionSlider.value


func _on_windSpeedSlider_value_changed(value):
	Globals.wind_speed = $VBoxContainer/windSpeedSlider.value


func _on_cdxSlider_value_changed(value):
	boat.CDx = $VBoxContainer/cdxSlider.value


func _on_cdySlider_value_changed(value):
	boat.CDy = $VBoxContainer/cdySlider.value


func _on_hullClSlider_value_changed(value):
	boat.Cl = $VBoxContainer/hullClSlider.value


func _on_sailcdSlider_value_changed(value):
	boat.sail_CD = $VBoxContainer/sailcdSlider.value


func _on_sailBaseDragSlider_value_changed(value):
	boat.sail_base_drag = $VBoxContainer/sailBaseDragSlider.value


func _on_sailClSlider_value_changed(value):
	boat.sail_Cl = $VBoxContainer/sailClSlider.value


func _on_ballastSlider_value_changed(value):
	boat.ballast_kg = $VBoxContainer/ballastSlider.value
