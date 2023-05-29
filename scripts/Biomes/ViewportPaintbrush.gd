extends SubViewport

var player : CharacterBody2D
@onready var brush = $PlayerPaintbrush
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#im poop
	var half = size * 0.5
	var p = player.position 
	p+= half
	brush.position = p
