extends Node

signal status_changed(message: String)

const WINDOWS_BASE = "https://firmware.ardupilot.org/Tools/MissionPlanner/sitl/"
const LINUX_URL = "https://firmware.ardupilot.org/Sub/latest/SITL_x86_64_linux_gnu/ardusub"
const ARGUMENTS = [
	"-S",
	"--model",
	"JSON",
	"--speedup",
	"1",
	"-I0",
	"--home",
	"33.810313,-118.39386700000001,0.0,270.0"
]

var process_id := -1
var starting := false


func start():
	if starting or process_id > 0:
		return
	var files := {}
	var executable := ""
	match OS.get_name():
		"Windows":
			executable = "ardusub.exe"
			files = {
				executable: WINDOWS_BASE + "ArduSub.elf",
				"cyggcc_s-1.dll": WINDOWS_BASE + "cyggcc_s-1.dll",
				"cygstdc++-6.dll": WINDOWS_BASE + "cygstdc++-6.dll",
				"cygwin1.dll": WINDOWS_BASE + "cygwin1.dll",
			}
		"Linux":
			if Engine.get_architecture_name() != "x86_64":
				status_changed.emit("Use external SITL on this Linux architecture")
				return
			executable = "ardusub"
			files = {executable: LINUX_URL}
		_:
			return

	starting = true
	for filename in files:
		if not await ensure_file(filename, files[filename]):
			starting = false
			status_changed.emit("SITL download failed. Keyboard controls are available.")
			return

	var binary := ProjectSettings.globalize_path("user://" + executable)
	if OS.get_name() == "Linux" and OS.execute("chmod", ["+x", binary]) != 0:
		starting = false
		status_changed.emit("Could not make ArduSub executable. Keyboard controls are available.")
		return

	process_id = OS.create_process(binary, ARGUMENTS)
	if process_id > 0:
		await get_tree().create_timer(0.5).timeout
	starting = false
	if process_id > 0 and OS.is_process_running(process_id):
		status_changed.emit("ArduSub SITL started")
	else:
		process_id = -1
		status_changed.emit("Could not start ArduSub. Keyboard controls are available.")


func ensure_file(filename: String, url: String) -> bool:
	var destination := "user://" + filename
	if FileAccess.file_exists(destination) and FileAccess.get_size(destination) > 0:
		return true
	var temporary := destination + ".part"
	var request := HTTPRequest.new()
	add_child(request)
	request.timeout = 60
	request.download_file = temporary
	status_changed.emit("Downloading " + filename)
	var downloaded := false
	if request.request(url) == OK:
		var response: Array = await request.request_completed
		downloaded = response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200
	request.queue_free()
	if downloaded and FileAccess.get_size(temporary) > 0:
		if DirAccess.rename_absolute(temporary, destination) == OK:
			return true
	if FileAccess.file_exists(temporary):
		DirAccess.remove_absolute(temporary)
	return false


func _exit_tree():
	if process_id > 0 and OS.is_process_running(process_id):
		OS.kill(process_id)
