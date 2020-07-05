extends InterpolatedCamera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.look_at($"/root/Node2D/ViewportCamera/Viewport/BlueRovHeavy/BlueRov".transform.origin, Vector3(0,1,0))
