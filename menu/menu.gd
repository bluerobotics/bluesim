extends Control


class LevelLoader:
	func find_packs() -> Dictionary:
		var user_levels := "user://levels"
		DirAccess.make_dir_recursive_absolute(user_levels)
		var directories := [user_levels]
		if OS.get_name() in ["Windows", "Linux"] and not OS.has_feature("editor"):
			directories.append(OS.get_executable_path().get_base_dir().path_join("levels"))
		var packs := {}
		for directory in directories:
			if not DirAccess.dir_exists_absolute(directory):
				continue
			for filename in DirAccess.get_files_at(directory):
				if filename.begins_with(".") or filename.get_extension().to_lower() != "pck":
					continue
				packs[filename] = ProjectSettings.globalize_path(directory.path_join(filename))
		return packs


func add_status(text: String):
	$HBoxContainer/Menu/statusLabel.text += text + "\n"


func set_version():
	var engine_version = Engine.get_version_info()
	$SubViewportContainer/versionLabel.text = (
		"Engine version: {major}.{minor}.{patch}-{hash} ({status})".format(engine_version)
	)


func create_level_buttons():
	var packs := LevelLoader.new().find_packs()
	var filenames := packs.keys()
	filenames.sort()
	for filename in filenames:
		var button := Button.new()
		button.text = filename.get_basename()
		button.add_theme_font_override(
			"font", $HBoxContainer/Menu/Buttons/poolLevel.get_theme_font("font")
		)
		button.pressed.connect(_on_custom_level_pressed.bind(packs[filename]))
		$HBoxContainer/Menu/Buttons.add_child(button)


func _ready():
	set_version()
	if not Globals.isHTML5:
		create_level_buttons()
	if Globals.isHTML5:
		add_status("Keyboard control available")
	elif OS.get_name() in ["Windows", "Linux"]:
		SitlLauncher.status_changed.connect(add_status)
		SitlLauncher.start()
	else:
		add_status("Keyboard control or external ArduSub SITL")


func _on_poolLevel_pressed():
	Globals.active_level = "res://levels/pool.tscn"
	SceneLoader.goto_scene("res://levels/baselevel.tscn")


func _on_CheckBox_toggled(button_pressed):
	Globals.wait_SITL = button_pressed


func _on_custom_level_pressed(pack_path: String):
	var filename := pack_path.get_file()
	if not ProjectSettings.load_resource_pack(pack_path, false):
		add_status("Could not open " + filename)
		return
	if not ResourceLoader.exists("res://custom_level.tscn", "PackedScene"):
		add_status(filename + " has no Godot 4 custom_level.tscn")
		return
	Globals.active_level = "res://custom_level.tscn"
	SceneLoader.goto_scene("res://levels/baselevel.tscn")
