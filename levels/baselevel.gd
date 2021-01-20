extends Control

func _ready():
	add_child(load(Globals.active_level).instance())
