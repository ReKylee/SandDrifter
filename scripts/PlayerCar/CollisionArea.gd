extends Area3D


var current_chunk : TerrainChunkCollision
var moving_chunk : TerrainChunkCollision
@onready var radius : float = $CollisionShape3D.shape.radius

func _process(delta):
	var bodies = get_overlapping_areas()
	if Engine.get_physics_frames() % 10 == 0:
		for chunk in bodies:
			
			if(chunk.global_position.distance_to(global_position) < radius):
				current_chunk = chunk.get_parent()
			else:
				chunk.get_parent().disable()
				
		if(is_instance_valid(current_chunk)):
			current_chunk.enable()
			#print(current_chunk.global_position)
