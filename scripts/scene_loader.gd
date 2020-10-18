extends Node

# Reference: https://docs.godotengine.org/en/3.0/tutorials/io/background_loading.html#doc-background-loading

var current_scene = null
var loader = null
var time_max = 1000/16 # ms
# Control loading scene
var wait_frames = 0

func show_error():
	print("Error while loading scene")

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

func goto_scene(path):
	loader = ResourceLoader.load_interactive(path)
	if loader == null: 
		show_error()
		return

	set_process(true)

	# get rid of the old scene
	current_scene.queue_free()

	get_tree().change_scene("res://scenery/misc/loading/loading.tscn")
	wait_frames = 1

func _process(time):	
	
	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	# wait for frames to let the "loading" animation to show up
	if wait_frames > 0: 
		wait_frames -= 1
		return

	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread

		# poll your loader
		var err = loader.poll()

		if err == ERR_FILE_EOF: # load finished
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			break
		elif err == OK:
			update_progress()
		else: # error during loading
			show_error()
			loader = null
			break

func update_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	var loading_scene = get_tree().get_current_scene()
	loading_scene.get_node("Label").text = "Loading.. (%d %%)" % (progress * 100)

func set_new_scene(scene_resource):
	current_scene = scene_resource.instance()
	get_node("/root").add_child(current_scene)
