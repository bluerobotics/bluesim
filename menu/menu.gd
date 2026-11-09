extends Control

class LevelLoader:
	var levels_path = "user://levels" if OS.get_name() in ["macOS", "Web"] or OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("levels")

	func ensure_levels_folder_exists():
		DirAccess.make_dir_recursive_absolute(levels_path)

	func list_available_external_levels():
		var dir = DirAccess.open(levels_path)
		if dir == null:
			return []
		print("Looking for additional levels at %s" % ProjectSettings.globalize_path(levels_path))
		dir.list_dir_begin()
		var found = []

		# list .pck files
		while true:
			var file = dir.get_next()
			if file.is_empty():
				break
			elif not file.begins_with(".") and file.ends_with(".pck"):
				found.append(file)
		dir.list_dir_end()

		found.sort()
		return found


func add_status(text: String):
	$HBoxContainer/Menu/statusLabel.text += text + "\n"

func set_version():
	var engine_version = Engine.get_version_info()
	$SubViewportContainer/versionLabel.text = "Engine version: {major}.{minor}.{patch}-{hash} ({status})".format(engine_version)

func create_level_buttons(levels):
	for filename in levels:
		var button = Button.new()
		button.text = filename.get_basename()
		button.add_theme_font_override("font", $HBoxContainer/Menu/Buttons/poolLevel.get_theme_font("font"))
		button.connect("pressed", Callable(self, "_on_customLevel_pressed").bind(filename))
		$HBoxContainer/Menu/Buttons.add_child(button)

func find_external_levels():
	var loader = LevelLoader.new()
	loader.ensure_levels_folder_exists()
	var levels = loader.list_available_external_levels()
	self.create_level_buttons(levels)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_version()
	find_external_levels()
	if Globals.isHTML5:
		add_status("Keyboard control available")
	elif OS.get_name() in ["Windows", "Linux"]:
		SitlLauncher.status_changed.connect(add_status)
		SitlLauncher.start()
	else:
		add_status("Keyboard control or external ArduSub SITL")

func _on_poolLevel_pressed():
	Globals.active_vehicle = "bluerovheavy"
	Globals.active_level = "res://levels/pool.tscn"
	SceneLoader.goto_scene("res://levels/baselevel.tscn")

func _on_CheckBox_toggled(button_pressed):
	Globals.wait_SITL = button_pressed

func _on_customLevel_pressed(filename):
	var path = ProjectSettings.globalize_path(LevelLoader.new().levels_path.path_join(filename))
	if not ProjectSettings.load_resource_pack(path, false):
		add_status("Could not open " + filename)
		return
	if not ResourceLoader.exists("res://custom_level.tscn", "PackedScene"):
		add_status(filename + " has no Godot 4 custom_level.tscn")
		return
	Globals.active_vehicle = "bluerovheavy"
	Globals.active_level = "res://custom_level.tscn"
	SceneLoader.goto_scene("res://levels/baselevel.tscn")
