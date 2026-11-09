extends Node

const LOADING_SCREEN = preload("res://scenery/misc/loading/loading.tscn")

var scene_path := ""

func goto_scene(path: String):
	if not scene_path.is_empty():
		return
	if ResourceLoader.load_threaded_request(path) != OK:
		push_error("Could not start loading " + path)
		return
	scene_path = path
	get_tree().change_scene_to_packed(LOADING_SCREEN)

func _process(_delta):
	if scene_path.is_empty():
		return
	var progress := []
	match ResourceLoader.load_threaded_get_status(scene_path, progress):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var scene := get_tree().current_scene
			if scene and scene.scene_file_path == LOADING_SCREEN.resource_path:
				scene.get_node("Label").text = "Loading... (%d%%)" % (progress[0] * 100)
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
			scene_path = ""
			get_tree().change_scene_to_packed(scene)
		_:
			push_error("Could not load " + scene_path)
			scene_path = ""
			get_tree().change_scene_to_file("res://menu/menu.tscn")
