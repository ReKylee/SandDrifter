extends SubViewport


var tires : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#im poop
	var half = size * 0.5
	for n in range(4):
		var p = tires[n].global_position 
		p+= half
		get_child(n).global_position = p
	
