extends Node

const colors = {
	"blizzard_blue": Color("#a5d6f1"),
}

export var surface_ambient = colors['blizzard_blue']
export var deep_ambient = colors['blizzard_blue']
export var current_ambient = colors['blizzard_blue']
export var deep_factor = 0.0
export var enable_godray = true
export var fancy_water = true
export var ping360_enabled = true
export var wait_SITL = false
export var isHTML5 = false
export var physics_rate = 60
export var wind_dir = 0
export var wind_speed = 5
var active_vehicle = null
var active_level = ""
var sitl_pid = 0


func _ready():
	isHTML5 = OS.get_name() == "HTML5"
