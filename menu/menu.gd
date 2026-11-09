extends Control

var downloaded_files = []

class LevelLoader:
	var levels_path = "user://levels" if OS.get_name() in ["macOS", "Web"] or OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("levels")

	func ensure_levels_folder_exists():
		DirAccess.make_dir_recursive_absolute(levels_path)

	func list_available_external_levels():
		var dir = DirAccess.open(levels_path)
		if dir == null:
			return {}
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

		# validate .pck files
		# They must have a custom_level.tscn file
		var valid = {}
		for file in found:
			if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(levels_path.path_join(file))):
				print("Failed to load file: " + file)
			# Now one can use the assets as if they had them in the project from the start
			var imported_scene = load("res://custom_level.tscn")
			if imported_scene == null:
				print("Unable to find 'custom_level.tscn' in file " + file)
				continue
			var level_name = file
			valid[file] = level_name
		return valid

func add_status(text: String):
	$HBoxContainer/Menu/statusLabel.text += text + "\n"

func set_version():
	var engine_version = Engine.get_version_info()
	$SubViewportContainer/versionLabel.text = "Engine version: {major}.{minor}.{patch}-{hash} ({status})".format(engine_version)

func download_file(url : String, file_name : String):
	add_status("downloading " + file_name)
	var http = HTTPRequest.new()
	add_child(http)
	http.set_download_file(file_name)
	http.request(url)
	http.connect("request_completed", Callable(self, "_on_download_finished").bind(file_name))

func _all_files_downloaded():
	if OS.get_name() == "Windows":
		return len(downloaded_files) == 4
	elif OS.get_name() == "Linux":
		return len(downloaded_files) == 1

func _on_download_finished(result, response_code, headers, body, file_name):
	add_status("done downloading " + file_name)
	downloaded_files.append(file_name)
	if _all_files_downloaded():
		_start_sitl()

func _start_sitl():

	if OS.get_name() == "Windows":
		var binary = ProjectSettings.globalize_path("user://ardusub.exe")
		print(binary)
		Globals.sitl_pid = OS.create_process(binary, ["-S","--model","JSON","--speedup","1","-I0","--home","33.810313,-118.39386700000001,0.0,270.0"], false)
		print(Globals.sitl_pid)
		add_status("SITL is running")
		$HBoxContainer/Menu/Buttons.visible = true

	elif OS.get_name() == "Linux":
		var binary = ProjectSettings.globalize_path("user://ardusub")
		print(binary)
		print(OS.execute("chmod", ["+x", binary]))
		Globals.sitl_pid = OS.create_process(binary, ["-S","--model","JSON","--speedup","1","-I0","--home","33.810313,-118.39386700000001,0.0,270.0"], false)
		add_status("SITL is running")
		$HBoxContainer/Menu/Buttons.visible = true

func _notification(what):
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		if Globals.sitl_pid > 0:
			OS.kill(Globals.sitl_pid)
		get_tree().quit()

func create_level_buttons(levels):
	for filename in levels.keys():
		var button = Button.new()
		button.text = levels[filename]
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
	get_tree().set_auto_accept_quit(false)
	find_external_levels()
	$HBoxContainer/Menu/Buttons.visible = false

	if OS.get_name() == "Windows":
		if not FileAccess.file_exists("user://ardusub.exe"):
			add_status("SITL binary not found, downloading...")
			download_file("https://firmware.ardupilot.org/Tools/MissionPlanner/sitl/ArduSub.elf", "user://ardusub.exe")
			download_file("https://firmware.ardupilot.org/Tools/MissionPlanner/sitl/cyggcc_s-1.dll", "user://cyggcc_s-1.dll")
			download_file("https://firmware.ardupilot.org/Tools/MissionPlanner/sitl/cygstdc++-6.dll", "user://cygstdc++-6.dll")
			download_file("https://firmware.ardupilot.org/Tools/MissionPlanner/sitl/cygwin1.dll", "user://cygwin1.dll")
		else:
			_start_sitl()
	elif OS.get_name() == "Linux":
		if not FileAccess.file_exists("user://ardusub"):
			download_file("https://firmware.ardupilot.org/Sub/latest/SITL_x86_64_linux_gnu/ardusub", "user://ardusub")
		else:
			_start_sitl()
	else:
		$HBoxContainer/Menu/Buttons.visible = true
		$HBoxContainer/Menu/CheckBox.visible = false
		add_status("Keyboard control available on %s" % OS.get_name())

func _on_poolLevel_pressed():
	Globals.active_vehicle = "bluerovheavy"
	Globals.active_level = "res://levels/pool.tscn"
	SceneLoader.goto_scene("res://levels/baselevel.tscn")

func _on_CheckBox_toggled(button_pressed):
	Globals.wait_SITL = button_pressed

func _on_customLevel_pressed(filename):
	Globals.active_vehicle = "bluerovheavy"
	Globals.active_level = "res://custom_level.tscn"
	ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(LevelLoader.new().levels_path.path_join(filename)))
	SceneLoader.goto_scene("res://levels/baselevel.tscn")
